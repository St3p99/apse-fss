void padding_vector(float* v, int n, int n_padding){
	for(n_padding--; n_padding >= 0; n_padding--){
		v[n+n_padding] = 0.0;
	}
}

void padding_matrix(float* m, int r, int c, int n_padding){
	for(int i = 0; i < r; i++){
		padding_vector(&m[i*(c+n_padding)], c, n_padding);
	}
}

void stampa_coordinate(float* m, int r, int c){
	for(int i = 0; i < r; i++){ //numero pesci
		printf("x[%d] = [", i);	  
		for(int coordinata = 0; coordinata < c - 1; coordinata++){ // coordinate pesce
      		float val_coordinata = m[(c)*(i)+coordinata];
			printf(" %f, ", val_coordinata);	  
		}
		float val_coordinata = m[(c)*(i)];
		printf(" %f]\n", m[(c)*(i) + c - 1]);	  
	}
}

int main(int argc, char** argv) {
    int r = 4;
    int c = 6;
    int padding = 2;
    float v[32] = 
    { 2, 3, 4, 5, 5, 1, 7, 7,
      1, 2, 4, 1, 5, 1, 7, 7,
      6, 6, 1, 8, 1, 2, 7, 7,
      5, 9, 2, 1, 8, 2, 7, 7
    };

    padding_matrix(v, r, c, padding);
    stampa_coordinate(v, r, c+padding);

}