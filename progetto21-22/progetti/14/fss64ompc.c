/**************************************************************************************
* 
* CdL Magistrale in Ingegneria Informatica
* Corso di Architetture e Programmazione dei Sistemi di Elaborazione - a.a. 2020/21
* 
* Progetto dell'algoritmo Fish School Search 221 231 a
* in linguaggio assembly x86-64 + SSE
* 
* Fabrizio Angiulli, aprile 2019
* 
**************************************************************************************/

/*
* 
* Software necessario per l'esecuzione:
* 
*    NASM (www.nasm.us)
*    GCC (gcc.gnu.org)
* 
* entrambi sono disponibili come pacchetti software 
* installabili mediante il packaging tool del sistema 
* operativo; per esempio, su Ubuntu, mediante i comandi:
* 
*    sudo apt-get install nasm
*    sudo apt-get install gcc
* 
* potrebbe essere necessario installare le seguenti librerie:
* 
*    sudo apt-get install lib64gcc-4.8-dev (o altra versione)
*    sudo apt-get install libc6-dev-i386
* 
* Per generare il file eseguibile:
* 
* nasm -f elf64 fss64.nasm && gcc -m64 -msse -O0 -no-pie sseutils64.o fss64.o fss64c.c -o fss64c -lm && ./fss64c $pars
* 
* oppure
* 
* ./runfss64
* 
*/

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <libgen.h>
#include <xmmintrin.h>
#include <omp.h>

#define	type		double
#define	MATRIX		type*
#define	VECTOR		type*


#define MAX_NUM_THREADS 7

typedef struct {
	MATRIX x; //posizione dei pesci
	VECTOR xh; //punto associato al minimo di f, soluzione del problema
	VECTOR c; //coefficienti della funzione
	VECTOR r; //numeri casuali
	int np; //numero di pesci, quadrato del parametro np
	int d; //numero di dimensioni del data set
	int padding_np; // numero di elementi di padding pesci
	int padding_d;  // numero di elementi di padding coordinate
	int iter; //numero di iterazioni
	type stepind; //parametro stepind
	type stepvol; //parametro stepvol
	type wscale; //parametro wscale
	int display;
	int silent;
} params;

/*
* 
*	Le funzioni sono state scritte assumento che le matrici siano memorizzate 
* 	mediante un array (double*), in modo da occupare un unico blocco
* 	di memoria, ma a scelta del candidato possono essere 
* 	memorizzate mediante array di array (double**).
* 
* 	In entrambi i casi il candidato dovr� inoltre scegliere se memorizzare le
* 	matrici per righe (row-major order) o per colonne (column major-order).
*
* 	L'assunzione corrente � che le matrici siano in row-major order.
* 
*/

void* get_block(int size, int elements) { 
	return _mm_malloc(elements*size, 32); 
}

void free_block(void* p) { 
	_mm_free(p);
}

MATRIX alloc_matrix(int rows, int cols) {
	return (MATRIX) get_block(sizeof(type),rows*cols);
}

void dealloc_matrix(MATRIX mat) {
	free_block(mat);
}

/*
* 
* 	load_data
* 	=========
* 
*	Legge da file una matrice di N righe
* 	e M colonne e la memorizza in un array lineare in row-major order
* 
* 	Codifica del file:
* 	primi 4 byte: numero di righe (N) --> numero intero
* 	successivi 4 byte: numero di colonne (M) --> numero intero
* 	successivi N*M*4 byte: matrix data in row-major order --> numeri doubleing-point a precisione singola
* 
*****************************************************************************
*	Se lo si ritiene opportuno, � possibile cambiare la codifica in memoria
* 	della matrice. 
*****************************************************************************
* 
*/
MATRIX load_data(char* filename, int *n, int *k) {
	FILE* fp;
	int rows, cols, status, i;
	
	fp = fopen(filename, "rb");
	
	if (fp == NULL){
		printf("'%s': bad data file name!\n", filename);
		exit(0);
	}
	
	status = fread(&cols, sizeof(int), 1, fp);
	status = fread(&rows, sizeof(int), 1, fp);
	
	MATRIX data = alloc_matrix(rows,cols);
	status = fread(data, sizeof(type), rows*cols, fp);
	fclose(fp);
	
	*n = rows;
	*k = cols;
	
	return data;
}

MATRIX load_coeff_padding(char* filename, int padding) {
	FILE* fp;
	int rows, cols, status, i;
	
	fp = fopen(filename, "rb");
	
	if (fp == NULL){
		printf("'%s': bad data file name!\n", filename);
		exit(0);
	}
	
	status = fread(&cols, sizeof(int), 1, fp);
	status = fread(&rows, sizeof(int), 1, fp);
	MATRIX data = alloc_matrix(rows, cols+padding);
	status = fread(data, sizeof(type), rows*cols, fp);
	// padding
	padding_vector(data, rows, padding);
	fclose(fp);
	
	return data;
}

MATRIX load_x_padding(char* filename, int *n, int *k, int* padding_d) {
	FILE* fp;
	int rows, cols, status, i;
	
	fp = fopen(filename, "rb");
	
	if (fp == NULL){
		printf("'%s': bad data file name!\n", filename);
		exit(0);
	}
	
	status = fread(&cols, sizeof(int), 1, fp);
	status = fread(&rows, sizeof(int), 1, fp);
	
	MATRIX data;
	int mul = 4;
	int resto_col = cols % mul;
	if( resto_col != 0 ){ // num_colonne non multiplo di mul (4)
		*padding_d = (cols - resto_col + mul) - cols; // numero di zeri da aggiungere ad ogni riga
		data = alloc_matrix(rows,cols + *padding_d);
		// int ptr = (int) data;		
		int n_cols_w_padding = cols + *padding_d; // numero di colonne considerando il padding
		for(int i = 0; i < rows; i++){
			// load riga
			status = fread( &data[i*(n_cols_w_padding)], sizeof(type), cols, fp);			
			// padding con *padding_d zeri alla fine della riga
			padding_vector(&data[i*(n_cols_w_padding)], cols, *padding_d);
			// ptr punterà all'inizio della prossima riga
			// ptr += (n_cols_w_padding)*sizeof(type);
		}
	}
	else{
		// num_colonne multiplo di mul (4)
		*padding_d = 0;
		data = alloc_matrix(rows,cols);
		status = fread(data, sizeof(type), rows*cols, fp);
	}
	fclose(fp);
	
	*n = rows;
	*k = cols;
	
	return data;
}


/*
* 	save_data
* 	=========
* 
*	Salva su file un array lineare in row-major order
*	come matrice di N righe e M colonne
* 
* 	Codifica del file:
* 	primi 4 byte: numero di righe (N) --> numero intero a 64 bit
* 	successivi 4 byte: numero di colonne (M) --> numero intero a 64 bit
* 	successivi N*M*4 byte: matrix data in row-major order --> numeri interi o doubleing-point a precisione singola
*/
void save_data(char* filename, void* X, int n, int k) {
	FILE* fp;
	int i;
	fp = fopen(filename, "wb");
	if(X != NULL){
		fwrite(&k, 4, 1, fp);
		fwrite(&n, 4, 1, fp);
		for (i = 0; i < n; i++) {
			fwrite(X, sizeof(type), k, fp);
			//printf("%i %i\n", ((int*)X)[0], ((int*)X)[1]);
			X += sizeof(type)*k;
		}
	}
	else{
		int x = 0;
		fwrite(&x, 4, 1, fp);
		fwrite(&x, 4, 1, fp);
	}
	fclose(fp);
}

// PROCEDURE ASSEMBLY

// extern void prova(params* input);
extern void calcola_y_asm_omp(VECTOR x, VECTOR y, int d, type step_ind, VECTOR r); // singolo pesce

extern void calcola_f_y_asm_omp(VECTOR x, VECTOR y, int d, VECTOR deltax, VECTOR c, type* y_2, type* c_y); // singolo pesce
extern void calcola_val_f_asm_omp(VECTOR x, int d, VECTOR c, type* x_2, type* c_x); // singolo pesce

extern void alimenta_asm_omp(int np, VECTOR deltaf, VECTOR pesi, type mindeltaf); // tutti i pesci
extern void calcola_I_asm_omp(VECTOR deltax, int np, int d, VECTOR deltaf, VECTOR I); // tutti i pesci
extern void mov_istintivo_asm_omp(MATRIX x, int d, VECTOR I); // singolo pesce
extern void baricentro_asm_omp(MATRIX x, int np, int d, VECTOR pesi, VECTOR baricentro, type* peso_tot_cur); // tutti i pesci

extern void mov_volitivo_asm_omp(VECTOR x, int d, type stepvol, VECTOR baricentro, type direzione, VECTOR r); // singolo pesce


// METODI DI SUPPORTO
void stampa_coordinate(params* input, int bool_print_padding){
	if(input->silent) return;
	int n_coordinate = input->d;
	int n_coordinate_tot = n_coordinate + input->padding_d;
	if(bool_print_padding){
		n_coordinate = n_coordinate_tot;
	}
	for(int pesce = 0; pesce < input->np; pesce++){ //numero pesci
		printf("x[%d] = [", pesce);	  
		for(int coordinata = 0; coordinata < n_coordinate - 1; coordinata++){ // coordinate pesce
      		type val_coordinata = input->x[n_coordinate_tot*(pesce)+coordinata];
			printf(" %f, ", val_coordinata);	  
		}
		type val_last_coordinata = input->x[n_coordinate_tot*(pesce)+n_coordinate - 1];
		printf(" %f]\n", val_last_coordinata);	  
	}
}

void stampa_matrice(params* input, MATRIX m, int r, int c, int bool_print_padding){
	if(input->silent) return;
	int n_coordinate = c;
	int n_coordinate_tot = n_coordinate + input->padding_d;
	if(bool_print_padding){
		n_coordinate = n_coordinate_tot;
	}
	for(int i = 0; i < r; i++){ //numero pesci
		printf("m[%d] = [", i);	  
		for(int coordinata = 0; coordinata < n_coordinate - 1; coordinata++){ // coordinate pesce
      		type val_coordinata = m[(n_coordinate_tot)*(i)+coordinata];
			printf(" %f, ", val_coordinata);	  
		}
		type val_last_coordinata = m[n_coordinate_tot*(i)+n_coordinate-1];
		printf(" %f]\n", val_last_coordinata);	  
	}
}

void padding_vector(VECTOR v, int n, int n_padding){
	for(n_padding--; n_padding >= 0; n_padding--){
		v[n+n_padding] = 0.0;
	}
}

void padding_matrix(MATRIX m, int r, int c, int n_padding){
	int cols_w_padding = c+n_padding;
	for(int i = 0; i < r; i++){
		padding_vector(&m[i*(cols_w_padding)], c, n_padding);
	}
}

// FSS
void fss(params* input){
	// -------------------------------------------------
	// Codificare qui l'algoritmo Fish Search School
	// -------------------------------------------------
	VECTOR pesi = alloc_matrix(1, input->np+input->padding_np);
	padding_vector(pesi, input->np, input->padding_np);
	#pragma omp parallel for num_threads(MAX_NUM_THREADS)
	for(int i = 0; i < input->np; i++){
		pesi[i] = input->wscale/2;
	}
	
	int it = 0;
	type peso_tot_cur = (input -> wscale/2)*(input -> np);
	type peso_tot_old = peso_tot_cur;
	type decadimento_ind = input->stepind/input->iter;
	type decadimento_vol = input->stepvol/input->iter;

	VECTOR baricentro = alloc_matrix(1, input->d + input->padding_d);
	padding_vector(baricentro, input->d, input->padding_d);
	VECTOR I = alloc_matrix(1, input->d + input->padding_d);
	padding_vector(I, input->d, input->padding_d);
	VECTOR f_cur = alloc_matrix(1, input->np + input->padding_np);
	padding_vector(f_cur, input->np, input->padding_np);
    VECTOR f_y = alloc_matrix(1, input->np + input->padding_np);
	padding_vector(f_y, input->np, input->padding_np);
	VECTOR deltaf = alloc_matrix(1, input->np + input->padding_np);
	padding_vector(deltaf, input->np, input->padding_np);
	MATRIX deltax = alloc_matrix(input->np, input->d + input->padding_d);
	padding_matrix(deltax, input->np, input->d, input->padding_d);
	MATRIX y = alloc_matrix(input->np, input->d + input->padding_d);
	padding_matrix(y, input->np, input->d, input->padding_d);

	type mindeltaf;
	type deltafsum;
	type f_min;
	int ind_f_min;
	int ind_r = 0;
	int n_pesci_tot      = input->np+input->padding_np;
	int n_coordinate_tot = input->d+input->padding_d;

	calcola_val_f(f_cur, input);
	calcola_f_min(input->np, f_cur, &f_min, &ind_f_min);
	if(!input->silent) printf("f min iniziale = %f\n", f_min);
	while (it < input->iter){
		//-- calcolo nuove coordinate, deltaf, deltax, mindeltaf, --//
		mov_individuali(input, deltaf, deltax, y, &mindeltaf, f_cur, f_y, &ind_r);
		if(mindeltaf < 0){ 
			//-- aggiorna pesi dei pesci --//
			alimenta_asm_omp(n_pesci_tot, deltaf, pesi, mindeltaf);
			//-- esegui movimento istintivo --//
			calcola_I_asm_omp(deltax, input->np, n_coordinate_tot, deltaf, I);
			mov_istintivo(input, I);
		}// else (mindeltaf >= 0) nessun pesce si è spostato durante il mov individuale
		//-- calcola baricentro --//
		baricentro_asm_omp(input->x, input->np, n_coordinate_tot, pesi, baricentro, &peso_tot_cur);
		//-- esegui movimento volitivo --/
		mov_volitivo(input, baricentro, &peso_tot_old, &peso_tot_cur, &ind_r);
		//-- aggiorna valori f_cur     --/
		calcola_val_f(f_cur, input);
		//-- aggiorna parametri --//
		input->stepind = input->stepind - decadimento_ind;
		input->stepvol = input->stepvol - decadimento_vol;
		it++;
	}
	calcola_f_min(input->np, f_cur, &f_min, &ind_f_min);
	if(!input->silent) printf("ind_f_min = %d\n", ind_f_min);
	//------- RETURN POS MIN ---------------
	input->xh = alloc_matrix(1, input->d);
	for(int j = 0; j < input->d; j++)
		input->xh[j] = input->x[ind_f_min*(input->d+input->padding_d)+j];
	if(!input->silent) printf("f_min = %f\n", f_min);
}

// MOVIMENTO INDIVIDUALE
void mov_individuali(params* input, VECTOR deltaf, MATRIX deltax, MATRIX y, type* mindeltaf, VECTOR f_cur, VECTOR f_y, int* ind_r){
	int n_pesci = input->np;
	int n_coordinate = input->d;
	int padding_d = input->padding_d;
	*mindeltaf = 1; // inizializzazione fittizia
	int n_coordinate_tot = n_coordinate+padding_d;
	
	#pragma omp parallel for num_threads(MAX_NUM_THREADS)
	for(int pesce = 0; pesce < n_pesci; pesce++){ // numero pesci	
			type y_2;
			type c_y;
			calcola_y_asm_omp(
				&(input->x[pesce*n_coordinate_tot]), 
				&(y[pesce*n_coordinate_tot]), 
				input->d, input->stepind, &(input->r[*ind_r+pesce*n_coordinate]));
			calcola_f_y_asm_omp(
				&(input->x[pesce*n_coordinate_tot]), 
				&(y[pesce*n_coordinate_tot]), 
				input->d+input->padding_d, 
				&(deltax[pesce*n_coordinate_tot]), 
				input->c, &y_2, &c_y
			);
			f_y[pesce] = exp(y_2) + y_2 - c_y;
	}
	*ind_r = *ind_r + n_pesci*n_coordinate;
	
	#pragma omp parallel for num_threads(MAX_NUM_THREADS)
	for(int pesce = 0; pesce < n_pesci; pesce++){ // aggiorna input->x e deltaf
		if(f_y[pesce] >= f_cur[pesce]){ // la posizione non è migliore
			deltaf[pesce] = 0.0; 
		}  // se il pesce non migliora non viene spostato
		else{ // il pesce ha acquisito una posizione migliore
			for(int coordinata = 0; coordinata < n_coordinate; coordinata++){ // sposta coordinate
	    		input->x[pesce*(n_coordinate_tot)+coordinata] = y[pesce*(n_coordinate_tot)+coordinata];
			}
			deltaf[pesce] = f_y[pesce] - f_cur[pesce];
			#pragma omp critical
			{
				if(deltaf[pesce] < *mindeltaf ) 
					*mindeltaf = deltaf[pesce]; //aggiorno il minimo deltaf
			}
			f_cur[pesce] = f_y[pesce]; // il nuovo valore del pesce
		}// else
	}
}//mov_individuale

void calcola_val_f(VECTOR f_cur, params* input){// conviene il suo utilizzo solo nell'inizializzazione
	int n_coordinate_tot = input->d + input->padding_d;

	type x_2;
  	type c_x;
	#pragma omp parallel for num_threads(MAX_NUM_THREADS) private(x_2, c_x)
	for(int pesce = 0; pesce < input->np; pesce++){
		calcola_val_f_asm_omp(&(input->x[pesce*n_coordinate_tot]), n_coordinate_tot, input->c, &x_2, &c_x);
		f_cur[pesce] = exp(x_2) + x_2 - c_x;
  	}
}//calcola_val_f

void mov_istintivo(params* input, VECTOR I){
	int n_coordinate_tot = input->d + input->padding_d;
	#pragma omp parallel for num_threads(MAX_NUM_THREADS)
	for(int pesce = 0; pesce < input->np; pesce++){
		mov_istintivo_asm_omp(&(input->x[pesce*n_coordinate_tot]), n_coordinate_tot, I);
	}
}

// MOV VOLITIVO
void mov_volitivo(params* input, VECTOR baricentro, type* peso_tot_old, type* peso_tot_cur, int* ind_r){
	type direzione = 1;
	if(*peso_tot_old < *peso_tot_cur)
		 direzione = -1; 
	int n_coordinate_tot = input->d + input->padding_d;
	#pragma omp parallel for num_threads(MAX_NUM_THREADS)
	for(int pesce = 0; pesce < input->np; pesce++){
		mov_volitivo_asm_omp(
			&(input->x[pesce*n_coordinate_tot]), 
			input->d, input->stepvol, baricentro, 
			direzione, &(input->r[*ind_r+pesce])
		);
	}
	*ind_r = *ind_r + input->np;
	*peso_tot_old = *peso_tot_cur;
}

void calcola_f_min(int n_pesci, VECTOR f_cur, type* f_min, int* ind_f_min){
	int pesce = 0;
	*f_min = f_cur[pesce];
	*ind_f_min = pesce;
	for(pesce = 1; pesce < n_pesci; pesce++){
		if( f_cur[pesce] < *f_min ){
			*f_min = f_cur[pesce];
			*ind_f_min = pesce;
		}
	}
}

int main(int argc, char** argv) {
	char fname[256];
	char* coefffilename = NULL;
	char* randfilename = NULL;
	char* xfilename = NULL;
	int i, j, k;
	double t;
	float time;
	
	//
	// Imposta i valori di default dei parametri
	//

	params* input = malloc(sizeof(params));

	input->x = NULL;
	input->xh = NULL;
	input->c = NULL;
	input->r = NULL;
	input->np = 25;
	input->d = 2;
	input->iter = 350;
	input->stepind = 1;
	input->stepvol = 0.1;
	input->wscale = 10;
	
	input->silent = 0;
	input->display = 0;

	//
	// Visualizza la sintassi del passaggio dei parametri da riga comandi
	//

	if(argc <= 1){
		printf("%s -c <c> -r <r> -x <x> -np <np> -si <stepind> -sv <stepvol> -w <wscale> -it <itmax> [-s] [-d]\n", argv[0]);
		printf("\nParameters:\n");
		printf("\tc: il nome del file ds2 contenente i coefficienti\n");
		printf("\tr: il nome del file ds2 contenente i numeri casuali\n");
		printf("\tx: il nome del file ds2 contenente le posizioni iniziali dei pesci\n");
		printf("\tnp: il numero di pesci, default 25\n");
		printf("\tstepind: valore iniziale del parametro per il movimento individuale, default 1\n");
		printf("\tstepvol: valore iniziale del parametro per il movimento volitivo, default 0.1\n");
		printf("\twscale: valore iniziale del peso, default 10\n");
		printf("\titmax: numero di iterazioni, default 350\n");
		printf("\nOptions:\n");
		printf("\t-s: modo silenzioso, nessuna stampa, default 0 - false\n");
		printf("\t-d: stampa a video i risultati, default 0 - false\n");
		exit(0);
	}

	//
	// Legge i valori dei parametri da riga comandi
	//

	int par = 1;
	while (par < argc) {
		if (strcmp(argv[par],"-s") == 0) {
			input->silent = 1;
			par++;
		} else if (strcmp(argv[par],"-d") == 0) {
			input->display = 1;
			par++;
		} else if (strcmp(argv[par],"-c") == 0) {
			par++;
			if (par >= argc) {
				printf("Missing coefficient file name!\n");
				exit(1);
			}
			coefffilename = argv[par];
			par++;
		} else if (strcmp(argv[par],"-r") == 0) {
			par++;
			if (par >= argc) {
				printf("Missing random numbers file name!\n");
				exit(1);
			}
			randfilename = argv[par];
			par++;
		} else if (strcmp(argv[par],"-x") == 0) {
			par++;
			if (par >= argc) {
				printf("Missing initial fish position file name!\n");
				exit(1);
			}
			xfilename = argv[par];
			par++;
		} else if (strcmp(argv[par],"-np") == 0) {
			par++;
			if (par >= argc) {
				printf("Missing np value!\n");
				exit(1);
			}
			input->np = atoi(argv[par]);
			par++;
		} else if (strcmp(argv[par],"-si") == 0) {
			par++;
			if (par >= argc) {
				printf("Missing stepind value!\n");
				exit(1);
			}
			input->stepind = atof(argv[par]);
			par++;
		} else if (strcmp(argv[par],"-sv") == 0) {
			par++;
			if (par >= argc) {
				printf("Missing stepvol value!\n");
				exit(1);
			}
			input->stepvol = atof(argv[par]);
			par++;
		} else if (strcmp(argv[par],"-w") == 0) {
			par++;
			if (par >= argc) {
				printf("Missing wscale value!\n");
				exit(1);
			}
			input->wscale = atof(argv[par]);
			par++;
		} else if (strcmp(argv[par],"-it") == 0) {
			par++;
			if (par >= argc) {
				printf("Missing iter value!\n");
				exit(1);
			}
			input->iter = atoi(argv[par]);
			par++;
		} else{
			printf("WARNING: unrecognized parameter '%s'!\n",argv[par]);
			par++;
		}
	}

	//
	// Legge i dati e verifica la correttezza dei parametri
	//

	if(coefffilename == NULL || strlen(coefffilename) == 0){
		printf("Missing coefficient file name!\n");
		exit(1);
	}

	if(randfilename == NULL || strlen(randfilename) == 0){
		printf("Missing random numbers file name!\n");
		exit(1);
	}

	if(xfilename == NULL || strlen(xfilename) == 0){
		printf("Missing initial fish position file name!\n");
		exit(1);
	}

	int x,y;
	int mul = 4;
	int resto_righe = input->np % mul;
	input->padding_np = 0;
	if( resto_righe != 0)
		input->padding_np = (input->np - resto_righe + mul) - input->np;

	input->r = load_data(randfilename, &x, &y); // no padding
	input->x = load_x_padding(xfilename, &x, &input->d, &input->padding_d);
	input->c = load_coeff_padding(coefffilename, input->padding_d);

	if(input->np < 0){
		printf("Invalid value of np parameter!\n");
		exit(1);
	}

	if(input->stepind < 0){
		printf("Invalid value of si parameter!\n");
		exit(1);
	}

	if(input->stepvol < 0){
		printf("Invalid value of sv parameter!\n");
		exit(1);
	}

	if(input->wscale < 0){
		printf("Invalid value of w parameter!\n");
		exit(1);
	}

	if(input->iter < 0){
		printf("Invalid value of it parameter!\n");
		exit(1);
	}

	//
	// Visualizza il valore dei parametri
	//

	if(!input->silent){
		printf("Coefficient file name: '%s'\n", coefffilename);
		printf("Random numbers file name: '%s'\n", randfilename);
		printf("Initial fish position file name: '%s'\n", xfilename);
		printf("Dimensions: %d\n", input->d);
		printf("Number of fishes [np]: %d\n", input->np);
		printf("Individual step [si]: %f\n", input->stepind);
		printf("Volitive step [sv]: %f\n", input->stepvol);
		printf("Weight scale [w]: %f\n", input->wscale);
		printf("Number of iterations [it]: %d\n", input->iter);
	}

	// COMMENTARE QUESTA RIGA!
	// prova(input);
	//

	//
	// Fish School Search
	//

	t = omp_get_wtime();
	fss(input);
	t = omp_get_wtime() - t;
	time = ((float)t);

	if(!input->silent)
		printf("FSS time = %.3f secs\n", time);
	else
		printf("%.3f\n", time);

	//
	// Salva il risultato di xh
	//
	sprintf(fname, "xh64_%d_%d_%d.ds2", input->d, input->np, input->iter);
	save_data(fname, input->xh, 1, input->d);
	if(input->display){
		if(input->xh == NULL)
			printf("xh: NULL\n");
		else{
			printf("xh: [");
			for(i=0; i<input->d-1; i++)
				printf("%f,", input->xh[i]);
			printf("%f]\n", input->xh[i]);
		}
	}

	if(!input->silent)
		printf("\nDone.\n");

	return 0;
}

// PER COMPILARE SENZA FILE ASM
// gcc -m32 -msse -O0 -no-pie ./sseutils32.o ./fss32c.c -o fss32c -lm && ./fss32c -c ../../data/coeff32_8.ds2 -r ../../data/rand32_8_64_250.ds2 -x ../../data/x32_8_64.ds2 -np 64 -si 1 -sv 0.1 -w 10 -it 250 -d;