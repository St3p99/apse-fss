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
* 	In entrambi i casi il candidato dovr� inoltre scegliere se memorizzare le
* 	matrici per righe (row-major order) o per colonne (column major-order).
*
* 	L'assunzione corrente � che le matrici siano in row-major order.
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

//extern void prova(params* input);

void fss(params* input){
	// -------------------------------------------------
	// Codificare qui l'algoritmo Fish Search School
	// -------------------------------------------------
	// NOTA: inizializzazione matrix x fatta nel main
	// 		 leggendo posizioni da file x32_8_64.ds2
	// -------------------------------------------------
	//-- inizializza peso Wi per ogni pesce i --//
	VECTOR pesi = alloc_matrix(1, input->np);
	int i;
	for (i = 0; i < input->np; i++){
		pesi[i] = input->wscale/2;
	}
	//creazione matrix y per salvare le coordinate ipotetiche
	MATRIX y = alloc_matrix(input->np, input->d);
	// -------------------------------------------------
	int it = 0;
	type peso_tot_old;
	type peso_tot_cur = (input->wscale/2)*input -> np;
	type decadimento_ind = input->stepind/input->iter;
	type decadimento_vol = input->stepvol/input->iter;
	VECTOR baricentro = alloc_matrix(1, input->d);
	VECTOR f_cur = alloc_matrix(1, input->np);
	VECTOR deltaf = alloc_matrix(1, input->np);
	MATRIX deltax = alloc_matrix(input->np, input->d);
	type mindeltaf;
	type f_min; // verificare
	int ind_f_min;
	int ind_r = 0;
	inizializza_val_f(f_cur, input, &f_min, &ind_f_min);
	while (it < input->iter){
		printf("WHILE\n");
		// considerare solo deltaf per i pesci che si muovono
		// aggiornare f_cur e aggiornare il valore minore
		mov_individuali(input, deltaf, deltax, y, &mindeltaf, f_cur, &f_min, &ind_f_min, &ind_r); //MORRONE
		printf("post ind\n");
		stampa_coordinate(input);
		alimenta(input, deltaf, pesi, &mindeltaf); //MANGIONE
		printf("post alimenta\n");
		stampa_coordinate(input);
		mov_istintivo(input, deltaf, deltax); //MANGIONE
		printf("post ist\n");
		stampa_coordinate(input);
		calcola_baricentro(input, pesi, baricentro, &peso_tot_cur); // ARCURI
		printf("post bar\n");
		stampa_coordinate(input);
		mov_volitivo(input, baricentro, &peso_tot_old, &peso_tot_cur, &ind_r);// ARCURI
		printf("post vol\n");
		stampa_coordinate(input);
		//------------UPDATE PARAMETERS------------------
		input->stepind = input->stepind - decadimento_ind;
		input->stepvol = input->stepvol - decadimento_vol;
		it++;
	}
	//------- RETURN POS MIN ---------------
	// xh punta all'inizio della riga (ALIASING AD X[ind_f_min*d])
	// si potrebbe accedere ad altre posizioni: ce ne fottiamo?
	input->xh = &input->x[ind_f_min*input->d];
}

void stampa_coordinate(params* input){
	for(int pesce = 0; pesce < input->np; pesce++){ //numero pesci
		printf("x[%d] = [", pesce);	  
		for(int coordinata = 0; coordinata < input->d - 1; coordinata++){ // coordinate pesce
      		type val_coordinata = input->x[(input->d)*(pesce)+coordinata];
			printf(" %f, ", val_coordinata);	  
		}
		type val_coordinata = input->x[(input->d)*(pesce+1)];
		printf(" %f]\n", input->x[(input->d)*(pesce+1)]);	  
	}
}

// MOVIMENTO INDIVIDUALE
/*commenti costruttivi:
vedere di utilizzare variabili ausiliarie delle funzioni per evitare di prelevare ogni volta i parametri in memoria, come quando
in assembly usi i registri per memorizzare i dati in memoria.
*/
void mov_individuali(params* input, VECTOR deltaf, MATRIX deltax, MATRIX y, type* mindeltaf, VECTOR f_cur, type* f_min, int* ind_f_min, int* ind_r){
  int n_pesci = input->np;
  int n_coordinate = input->d;
  type sum_delta_f = 0.0; //sommo tutti i deltaf validi per il movimento istintivo
  *mindeltaf = 1; //inizializzazione fittizia, non può essere zero
  type copy_stepind = input->stepind;
  type y_quadro;
  type c_per_y;
  int spostati = 0; // è un contatore che conta il numero di pesci spostati;
  type rand;
  for(int pesce = 0; pesce < n_pesci; pesce++){ //numero pesci
    y_quadro = 0.0;
    c_per_y = 0.0;	
	for(int coordinata = 0; coordinata < n_coordinate; coordinata++){ // coordinate pesce
      type val_coordinata = input->x[(n_coordinate)*(pesce)+coordinata];
      type coef_coordinata = input->c[coordinata];
	  rand = input->r[*ind_r]*2 - 1; 
	  *ind_r = *ind_r + 1;
      type coord_j_pesce_i = val_coordinata+(rand)*(copy_stepind); // coordinata j-esima del pesce i-esimo (scritto come def (1) nella traccia)
	  y[(n_coordinate)*(pesce)+coordinata] = coord_j_pesce_i; 
      
	  y_quadro += (coord_j_pesce_i)*(coord_j_pesce_i);
      c_per_y += (coord_j_pesce_i)*(coef_coordinata);
      deltax[n_coordinate+pesce*coordinata] = coord_j_pesce_i - val_coordinata; //aggiorno direttamente il delta x
    }//iterazione sulle coordinate di ogni singolo pesce
    type val_f_pesce_cur_posy = exp(y_quadro) + y_quadro - c_per_y;
	printf("valfx = %f\n", f_cur[pesce]);
	printf("valfy = %f\n", val_f_pesce_cur_posy);
	if(val_f_pesce_cur_posy >= f_cur[pesce]){ //vuol dire che non è una posizione migliore
      deltaf[pesce] = 0.0; 
      // non  è necessario azzerrare le coordinate deltaX del pesce, poichè basta controllare il suo deltaf prima di accedervi.
    }// se il pesce non migliora il suo valore nella nuova coordinata non si sposta
    else{// il pesce ha acquisito una posizione migliore
	  spostati++;
      deltaf[pesce] = val_f_pesce_cur_posy - f_cur[pesce];
      if(deltaf[pesce] < *mindeltaf || *mindeltaf == 1) {
		  *mindeltaf = deltaf[pesce]; //aggiorno il massimo deltaf
	  }
      sum_delta_f += deltaf[pesce];
      if(val_f_pesce_cur_posy <= *f_min){
        *f_min = val_f_pesce_cur_posy;
        *ind_f_min = pesce; // capire se nel movimento volitivo si spostano tutti è inutile in questa fase calcolare f_min, ind_f_min
      }//aggiornamento valore migliore
	  f_cur[pesce] = val_f_pesce_cur_posy; // il nuovo valore del pesce
    }// else
  }//for
  printf("SPOSTATI = %d\n", spostati);
  if( spostati >= input->np/2){ // sono maggiori i pesci che si sono spostati, quindi mi conviene sovrascrivere y con i pesci che non si sono spostati
	for (int pesce = 0; pesce < n_pesci; ++pesce){ // se i pesci non si sono spostati deltaf = 0
      if(deltaf[pesce] == 0){ // se il pesce non si è spostato (deltaf = 0)
        for(int coordinata = 0; coordinata < n_coordinate; coordinata++){
          y[n_coordinate*pesce+coordinata] = input->x[n_coordinate*pesce+coordinata];
        }//tutte le coordinate di quel pesce	
      }//if 	
    }//for	
    int tmp = (int) input->x;
	input->x = y;
	y = (float *) tmp;
  }//if spostati >= rimasti	
  else{ // sono maggiori i pesci che non si sono spostati
    for (int pesce = 0; pesce < n_pesci; ++pesce){ // se i pesci si sono spostati deltaf è diverso da 0
	  if(deltaf[pesce] != 0){
        for(int coordinata = 0; coordinata < n_coordinate; coordinata++){
		  input->x[n_coordinate*pesce+coordinata] = y[n_coordinate*pesce+coordinata];
        }//tutte le coordinate di quel pesce	
      }//if 	
    }//for	
  }//else
}//mov_individuale

void inizializza_val_f(VECTOR f_cur, params* input, type* f_min, int* ind_f_min){// conviene il suo utilizzo solo nell'inizializzazione
  int n_pesci = input->np;
  int n_coordinate = input->d;
  int pesce = 0;
  int coordinata;
  type val_f_pesce_cur;

  calcola_f(input, pesce, &val_f_pesce_cur); // calcolo il valore della funzione del primo pesce per inizializzare i parametri  f_min e ind_f_min
  f_cur[pesce] = val_f_pesce_cur;
  *f_min = val_f_pesce_cur; 
  *ind_f_min = pesce;

  for(pesce = 1; pesce < n_pesci; pesce++){ //numero pesci, ovviamente escludi il primo che hai già calcolato
	calcola_f(input, pesce, &val_f_pesce_cur);	
    f_cur[pesce] = val_f_pesce_cur;
    if(val_f_pesce_cur < *f_min){
      *f_min = val_f_pesce_cur;
      *ind_f_min = pesce;
    }//inizializzazione del migliore	  
  }//iterazione su tutti i pesci
}//inizializza_val_f

void calcola_f(params* input, int pesce, type* ret){
	type val_i; 
  	type coef_i;
	type x_quadro = 0.0;
  	type c_per_x = 0.0;
	  
	for(int i = 0; i < input->d; i++){ // coordinate pesce
      //rappresentazione per righe della matrice quindi A[i,j] -> A[n*i+j] dove n indica il numero di collone
      val_i = input->x[pesce*input->d+i]; //valore coordinata
      coef_i = input->c[i]; //coefficiente corrispondente alla coordinata corrente

      x_quadro += (val_i*val_i);
      c_per_x += (val_i*coef_i);
    }//iterazione sulle coordinate di ogni singolo pesce
    *ret = exp(x_quadro) + x_quadro - c_per_x;
}

// MOV VOLITIVO
void mov_volitivo(params* input,  VECTOR baricentro, type* peso_tot_old, type* peso_tot_cur, int* ind_r){
	type direzione = 1;
	if(peso_tot_old < peso_tot_cur){ direzione = -1; } 
	type dist;
	type rand;
	for(int i = 0; i < input -> np; i++){
		calcola_distanza(input, i, baricentro, &dist);
		if( dist == 0 ){
				printf("dist = 0\n");
				exit(0);
		}
		for(int j = 0; j < input -> d; j++){
			rand = input->r[*ind_r]; 
			*ind_r = *ind_r + 1;
			input->x[i*(input->d)+j] += (direzione)*(input->stepvol)*(rand)*((input->x[i*(input->d)+j]-baricentro[j])/dist);
		}
	}
	peso_tot_old = peso_tot_cur;
}

void calcola_distanza (params* input, int i, VECTOR b, type* distanza){
	type somma = 0;
	for(int j = 0; j < input -> d; j++){
		somma += (input->x[i*input->d+j]- b[j])*(input->x[i*input->d+j]-b[j]);
	}
	*distanza = sqrt(somma); // verificare il tipo e la funzione
}

void calcola_baricentro (params* input, VECTOR pesi, VECTOR baricentro, type* peso_tot_cur){
	
	numeratore_baricentro(input, pesi, baricentro);
	calcola_peso_tot_branco(input, pesi, peso_tot_cur);
	for(int i = 0; i < input -> d; i++){
		baricentro[i] = baricentro[i]/(*peso_tot_cur);
	}
}

void calcola_peso_tot_branco (params* input, VECTOR pesi, type* ret){
	printf("CALCOLA PESO TOT BRANCO\n");
	for (int i = 0; i < input->np; i++){
		*ret = *ret + pesi[i];
	}
}

void numeratore_baricentro ( params* input, VECTOR pesi, VECTOR numeratore ){
	for(int i = 0; i < input-> np; i++ ){
		for(int j = 0; j < input -> d; j++ ){
			numeratore[j] += input->x[i*(input->d)+j]*pesi[i];
		}
	}
}

// MOV ISTINTIVO
void alimenta(params* input, VECTOR deltaf, VECTOR pesi, type* mindeltaf){
	printf("ALIMENTA\n");	
	int i = 0;
	while(i < input->np){
		if( *mindeltaf == 0 ){
			printf("riga 403 mindeltaf = 0\n");
			exit(0);
		}
		pesi[i] = pesi[i] + (deltaf[i]/(*mindeltaf));
		i = i+1;
	}
	// Assumo che il valore di mindeltaf sia quello corretto
	// ovvero il max valore di f calcolato rispetto i pesci
	// che hanno eseguito un movimento valido
}

void mov_istintivo(params* input, VECTOR deltaf, VECTOR deltax){
	type deltafsum = 0.0;
	int i = 0;
	VECTOR ret = alloc_matrix(1, input->d);
	while( i < input->np){
		if(deltaf[i] != 0){
			deltafsum += deltaf[i];
			for(int j=0; j < input->d;j++){
				ret[j] += deltax[i*(input->d)+j]*(deltaf[i]); 
			}
		}
		i++;
	}
	if( deltafsum == 0 ){
		dealloc_matrix(ret);
		return;
	}
	for(int j=0; j < input->d; j++){
		ret[j] = ret[j]/deltafsum; 
	}
	for(int i = 0; i < input->np; i++){
		for(int j = 0; j < input->d; j++){
			input->x[i*input->d+j] += ret[j];
		}
	}
	dealloc_matrix(ret);
	
}

int main(int argc, char** argv) {
	char fname[256];
	// char* coefffilename = "./apse-fss/progetto21-22/data/coeff32_8.ds2";
	// char* randfilename = "./apse-fss/progetto21-22/data/rand32_8_64_250.ds2";
	// char* xfilename = "./apse-fss/progetto21-22/data/x32_8_64.ds2";
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
	//prova(input);
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
// COMPILARE SENZA FILE ASM
// gcc -m32 -msse -O0 -no-pie ./sseutils32.o ./fss32c.c -o fss32c -lm
// ESEGUIRE SENZA FILE ASM
// ./fss32c -c ../../data/coeff32_8.ds2 -r ../../data/rand32_8_64_250.ds2 -x ../../data/x32_8_64.ds2 -np 25 -si 1 -sv 0.1 -w 10 -it 350 -d