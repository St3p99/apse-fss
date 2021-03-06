/**************************************************************************************
* 
* CdL Magistrale in Ingegneria Informatica
* Corso di Architetture e Programmazione dei Sistemi di Elaborazione - a.a. 2020/21
* 
* Progetto dell'algoritmo Fish School Search 221 231 a
* in linguaggio assembly x86-32 + SSE
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
*    sudo apt-get install lib32gcc-4.8-dev (o altra versione)
*    sudo apt-get install libc6-dev-i386
* 
* Per generare il file eseguibile:
* 
* nasm -f elf32 fss32.nasm && gcc -m32 -msse -O0 -no-pie sseutils32.o fss32.o fss32c.c -o fss32c -lm && ./fss32c $pars
* 
* oppure
* 
* ./runfss32
* 
*/

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <libgen.h>
#include <xmmintrin.h>

#define	type		float
#define	MATRIX		type*
#define	VECTOR		type*

typedef struct {
	MATRIX x; //posizione dei pesci
	VECTOR xh; //punto associato al minimo di f, soluzione del problema
	VECTOR c; //coefficienti della funzione
	VECTOR r; //numeri casuali
	int np; //numero di pesci, quadrato del parametro np
	int d; //numero di dimensioni del data set
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
* 	mediante un array (float*), in modo da occupare un unico blocco
* 	di memoria, ma a scelta del candidato possono essere 
* 	memorizzate mediante array di array (float**).
* 
* 	In entrambi i casi il candidato dovr??? inoltre scegliere se memorizzare le
* 	matrici per righe (row-major order) o per colonne (column major-order).
*
* 	L'assunzione corrente ??? che le matrici siano in row-major order.
* 
*/

void* get_block(int size, int elements) { 
	return _mm_malloc(elements*size,16); 
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
* 	successivi N*M*4 byte: matrix data in row-major order --> numeri floating-point a precisione singola
* 
*****************************************************************************
*	Se lo si ritiene opportuno, ??? possibile cambiare la codifica in memoria
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

<<<<<<< HEAD:progetto21-22/progetti/14/c_code/fss32c.c
=======
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
		int n_cols_w_padding = cols + *padding_d; // numero di colonne considerando il padding
		for(int i = 0; i < rows; i++){
			// load riga
			status = fread(&data[i*(n_cols_w_padding)], sizeof(type), cols, fp);			
			// padding con *padding_d zeri alla fine della riga
			padding_vector(&data[i*(n_cols_w_padding)], cols, *padding_d);
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


>>>>>>> develop:progetto21-22/progetti/14/fss32c.c
/*
* 	save_data
* 	=========
* 
*	Salva su file un array lineare in row-major order
*	come matrice di N righe e M colonne
* 
* 	Codifica del file:
* 	primi 4 byte: numero di righe (N) --> numero intero a 32 bit
* 	successivi 4 byte: numero di colonne (M) --> numero intero a 32 bit
* 	successivi N*M*4 byte: matrix data in row-major order --> numeri interi o floating-point a precisione singola
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

// METODI DI SUPPORTO
void stampa_coordinate(params* input){
	if(input->silent) return;
	for(int pesce = 0; pesce < input->np; pesce++){ //numero pesci
		printf("x[%d] = [", pesce);	  
		for(int coordinata = 0; coordinata < input->d - 1; coordinata++){ // coordinate pesce
      		type val_coordinata = input->x[(input->d)*(pesce)+coordinata];
			printf(" %f, ", val_coordinata);	  
		}
		type val_coordinata = input->x[(input->d)*(pesce)];
		printf(" %f]\n", input->x[(input->d)*(pesce) + input->d - 1]);	  
	}
}

// FSS
void fss(params* input){
	// -------------------------------------------------
	// Codificare qui l'algoritmo Fish Search School
	// -------------------------------------------------
	// NOTA: inizializzazione matrix x fatta nel main
	// 		 leggendo posizioni da file x32_8_64.ds2
	// -------------------------------------------------
	//-- inizializza peso Wi per ogni pesce i --//
<<<<<<< HEAD:progetto21-22/progetti/14/c_code/fss32c.c
	// stampa_coordinate(input);
	VECTOR pesi = alloc_matrix(1, input->np);
=======
	VECTOR pesi = alloc_matrix(1, input->np+input->padding_np);
	padding_vector(pesi, input->np, input->padding_np);
>>>>>>> develop:progetto21-22/progetti/14/fss32c.c
	int i;
	for(i = 0; i < input->np; i++){
		pesi[i] = input->wscale/2;
	}
	// -------------------------------------------------
	int it = 0;
	type peso_tot_cur = (input -> wscale/2)*(input -> np);
	type peso_tot_old = peso_tot_cur;
	type decadimento_ind = input->stepind/input->iter;
	type decadimento_vol = input->stepvol/input->iter;

	VECTOR baricentro = alloc_matrix(1, input->d);
	VECTOR I = alloc_matrix(1, input->d);
	VECTOR f_cur = alloc_matrix(1, input->np);
    VECTOR f_y = alloc_matrix(1, input->np);
	VECTOR deltaf = alloc_matrix(1, input->np);
	MATRIX deltax = alloc_matrix(input->np, input->d);
	//-- allocazione matrix y per salvare le coordinate a seguito del mov. individuale --//
	MATRIX y = alloc_matrix(input->np, input->d);

	type mindeltaf;
	type f_min;
	int ind_f_min;
	int ind_r = 0;

	//-- calcola val_f su coordinate iniziali x e inizializza f_min e ind_f_min
	calcola_val_f(f_cur, input);
	calcola_f_min(input->np, f_cur, &f_min, &ind_f_min);
	if(!input->silent) printf("f min iniziale = %f\n", f_min);
	int count = 0;
	while (it < input->iter){
		//-- calcolo nuove coordinate, deltaf, deltax, mindeltaf, --//
		mov_individuali(input, deltaf, deltax, y, &mindeltaf, f_cur, f_y, &ind_r);
		//-- aggiorna pesi dei pesci --//
		if(mindeltaf < 0){
			alimenta(input, deltaf, pesi, &mindeltaf);
			//-- esegui movimento istintivo --//
			mov_istintivo(input, deltaf, deltax, I);
		}
		//-- calcola baricentro --//
		calcola_baricentro(input, pesi, baricentro, &peso_tot_cur);
		//-- esegui movimento volitivo --/
		mov_volitivo(input, baricentro, &peso_tot_old, &peso_tot_cur, &ind_r);
		calcola_val_f(f_cur, input);
		//-- aggiorna parametri --//
		input->stepind = input->stepind - decadimento_ind;
		input->stepvol = input->stepvol - decadimento_vol;
		it++;
	}
	calcola_f_min(input->np, f_cur, &f_min, &ind_f_min);
	if(!input->silent) printf("ind_f_min = %d\n", ind_f_min);
	//------- RETURN POS MIN ---------------
	// input->xh = &input->x[ind_f_min*(input->d)];
	input->xh = alloc_matrix(1, input->d);
	for(int j = 0; j < input->d; j++)
		input->xh[j] = input->x[ind_f_min*input->d+j];
	if(!input->silent) printf("f_min = %f\n", f_min);
}

// MOVIMENTO INDIVIDUALE
void mov_individuali(params* input, VECTOR deltaf, MATRIX deltax, MATRIX y, type* mindeltaf, VECTOR f_cur, VECTOR f_y, int* ind_r){
  int n_pesci = input->np;
  int n_coordinate = input->d;
  *mindeltaf = 1; // inizializzazione fittizia
  type copy_stepind = input->stepind;
  type y_quadro;
  type c_per_y;
  int spostati = 0; // conta il numero di pesci spostati;
  type rand;
  for(int pesce = 0; pesce < n_pesci; pesce++){ // numero pesci
    y_quadro = 0.0;
    c_per_y = 0.0;	
	for(int coordinata = 0; coordinata < n_coordinate; coordinata++){ // coordinate pesce
      	type val_coordinata = input->x[(n_coordinate)*(pesce)+coordinata];
      	type coef_coordinata = input->c[coordinata];
		rand = (input->r[*ind_r]*2) - 1; 
	  	*ind_r = *ind_r + 1;
		
      	type coord_j_pesce_i = val_coordinata+((rand)*(copy_stepind)); // coordinata j-esima del pesce i-esimo (scritto come def (1) nella traccia)
	  	y[((n_coordinate)*(pesce))+coordinata] = coord_j_pesce_i; 
		type y_ij = y[((n_coordinate)*(pesce))+coordinata];
      
	  	y_quadro += (y_ij)*(y_ij);
      	c_per_y += (y_ij)*(coef_coordinata);
      	deltax[(n_coordinate)*pesce+coordinata] = y_ij - val_coordinata; // aggiorno direttamente il delta x
    }  // for coordinate
	f_y[pesce] = exp(y_quadro) + y_quadro - c_per_y;

    if(f_y[pesce] >= f_cur[pesce]){ // la posizione non ?? migliore
        deltaf[pesce] = 0.0; 
        /* non  ?? necessario azzerrare le coordinate deltaX del pesce
        poich?? basta controllare il suo deltaf prima di accedervi. */
    } // se il pesce non migliora non viene spostato
    else{ // il pesce ha acquisito una posizione migliore
        spostati++;
        deltaf[pesce] = f_y[pesce] - f_cur[pesce];
        if(deltaf[pesce] < *mindeltaf ) *mindeltaf = deltaf[pesce]; //aggiorno il minimo deltaf
    	    f_cur[pesce] = f_y[pesce]; // il nuovo valore del pesce
    }// else
  }//for
  
    if( spostati >= n_pesci/2 ){ // sono maggiori i pesci che si sono spostati, quindi mi conviene sovrascrivere y con i pesci che non si sono spostati
        for (int pesce = 0; pesce < n_pesci; pesce++){ // se i pesci non si sono spostati deltaf = 0
            if(deltaf[pesce] == 0){ // se il pesce non si ?? spostato (deltaf = 0)
                for(int coordinata = 0; coordinata < n_coordinate; coordinata++){
                    y[(n_coordinate)*pesce+coordinata] = input->x[(n_coordinate)*pesce+coordinata];
                }//tutte le coordinate di quel pesce	
            }//if 	
        }//for	
        int tmp = (int) input->x;
        input->x = y;
        y = (float *) tmp;
    }//if spostati >= rimasti	
    else{ // sono maggiori i pesci che non si sono spostati
        for(int pesce = 0; pesce < n_pesci; pesce++){ // se i pesci si sono spostati deltaf ?? diverso da 0
            if(deltaf[pesce] != 0){
                for(int coordinata = 0; coordinata < n_coordinate; coordinata++){
                    input->x[(n_coordinate)*pesce+coordinata] = y[(n_coordinate)*pesce+coordinata];
                }//tutte le coordinate di quel pesce	
            }//if 	
        }//for	
    }//else
}//mov_individuale

void calcola_val_f(VECTOR f_cur, params* input){// conviene il suo utilizzo solo nell'inizializzazione
  int n_pesci = input->np;
  int n_coordinate = input->d;
  int pesce = 0;
  int coordinata;
  type val_f_pesce_cur;

  calcola_f_pesce(input, pesce, &val_f_pesce_cur); // calcolo il valore della funzione del primo pesce per inizializzare i parametri  f_min e ind_f_min
  f_cur[pesce] = val_f_pesce_cur;

  for(pesce = 1; pesce < n_pesci; pesce++){ //numero pesci, ovviamente escludi il primo che hai gi?? calcolato
	calcola_f_pesce(input, pesce, &val_f_pesce_cur);	
    f_cur[pesce] = val_f_pesce_cur;
  }//iterazione su tutti i pesci
}//inizializza_val_f

void calcola_f_pesce(params* input, int pesce, type* ret){
	int n_coordinate = input->d;
	type val_i; 
  	type coef_i;
	type x_quadro = 0.0;
  	type c_per_x = 0.0;
	  
	for(int i = 0; i < n_coordinate; i++){ // coordinate pesce
      //rappresentazione per righe della matrice quindi A[i,j] -> A[n*i+j] dove n indica il numero di collone
      val_i = input->x[pesce*(n_coordinate)+i]; //valore coordinata
      coef_i = input->c[i]; //coefficiente corrispondente alla coordinata corrente

      x_quadro += (val_i*val_i);
      c_per_x += (val_i*coef_i);
    }//iterazione sulle coordinate di ogni singolo pesce
    *ret = exp(x_quadro) + x_quadro - c_per_x;
}

// MOV ISTINTIVO
void alimenta(params* input, VECTOR deltaf, VECTOR pesi, type* mindeltaf){
	int n_pesci = input->np;
	for(int pesce = 0; pesce < n_pesci; pesce++)
		pesi[pesce] = pesi[pesce] + (deltaf[pesce]/(*mindeltaf));
	// Assumo che il valore di mindeltaf sia quello corretto
	// ovvero il max valore di f calcolato rispetto i pesci
	// che hanno eseguito un movimento valido
}

void mov_istintivo(params* input, VECTOR deltaf, VECTOR deltax, VECTOR I){
	int n_pesci = input->np;
	int n_coordinate = input->d;
	int pesce = 0;
	type deltafsum = deltaf[pesce];
	
	for(int j=0; j < n_coordinate; j++){
		I[j] = deltax[pesce*(n_coordinate)+j]*(deltaf[pesce]); 
	} // Inizializza I per il primo pesce
	
	for(pesce = 1; pesce < n_pesci; pesce++){
		deltafsum += deltaf[pesce]; // calcola denominatore
		for(int j=0; j < n_coordinate;j++){
			I[j] += deltax[pesce*(n_coordinate)+j]*(deltaf[pesce]); 
		}
	}
	// if( deltafsum == 0 ) return;
	for(int j=0; j < n_coordinate; j++){
		I[j] = I[j]/deltafsum;
	}
	for(int i = 0; i < n_pesci; i++){
		for(int j = 0; j < n_coordinate; j++){
			input->x[i*(n_coordinate)+j] += I[j];
		}
	}
}

// MOV VOLITIVO
void mov_volitivo(params* input,  VECTOR baricentro, type* peso_tot_old, type* peso_tot_cur, int* ind_r){
	type direzione = 1;
	if(*peso_tot_old < *peso_tot_cur){
		 direzione = -1; 
	} 
	type dist;
	type rand;
	int n_pesci = input->np;
	int n_coordinate = input->d;
	for(int i = 0; i < n_pesci; i++){
		calcola_distanza(input, i, baricentro, &dist);
		rand = input->r[*ind_r]; 
		*ind_r = *ind_r + 1;
		for(int j = 0; j < n_coordinate; j++){
			input->x[i*(n_coordinate)+j] += (direzione)*(input->stepvol)*(rand)*((input->x[i*(n_coordinate)+j]-baricentro[j])/dist);
		}
	}
	*peso_tot_old = *peso_tot_cur;
}

void calcola_distanza (params* input, int i, VECTOR b, type* distanza){
	int n_coordinate = input->d;
	type somma = 0;
	for(int j = 0; j < n_coordinate; j++){
		type var = input->x[i*(n_coordinate)+j]-b[j];
		somma += var*var;
	}
	*distanza = sqrt(somma);
}

void calcola_baricentro (params* input, VECTOR pesi, VECTOR baricentro, type* peso_tot_cur){
	int n_coordinate = input->d;
	numeratore_baricentro(input, pesi, baricentro);
	calcola_peso_tot_branco(input, pesi, peso_tot_cur);
	for(int i = 0; i < n_coordinate; i++){
		baricentro[i] = baricentro[i]/(*peso_tot_cur);
	}
}

void calcola_peso_tot_branco (params* input, VECTOR pesi, type *ret){
	int n_pesci = input->np;
	*ret = 0;
	for (int i = 0; i < n_pesci; i++){
		*ret = *ret + pesi[i];
	}
}

void numeratore_baricentro ( params* input, VECTOR pesi, VECTOR numeratore ){
	int n_pesci = input->np;
	int n_coordinate = input->d;
	int i = 0;
	for(int j = 0; j < n_coordinate; j++ ){
		numeratore[j] = input->x[i*(n_coordinate)+j]*pesi[i];
	}
	for(i++; i < n_pesci; i++ ){
		for(int j = 0; j < n_coordinate; j++ ){
			numeratore[j] += input->x[i*(n_coordinate)+j]*pesi[i];
		}
	}
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
	clock_t t;
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
	input->c = load_data(coefffilename, &input->d, &y);
	input->r = load_data(randfilename, &x, &y);
	input->x = load_data(xfilename, &x, &y);

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

	t = clock();
	fss(input);
	t = clock() - t;
	time = ((float)t)/CLOCKS_PER_SEC;

	if(!input->silent)
		printf("FSS time = %.3f secs\n", time);
	else
		printf("%.3f\n", time);

	//
	// Salva il risultato di xh
	//
	sprintf(fname, "xh32_%d_%d_%d.ds2", input->d, input->np, input->iter);
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
