 # FSS32

 ## Movimento individuale
 
 ```C
 if( spostati >= n_pesci/2 ){ 
	for (int pesce = 0; pesce < n_pesci; pesce++){ 
      if(deltaf[pesce] == 0){ // se il pesce non si è spostato (deltaf = 0)
        for(int coordinata = 0; coordinata < n_coordinate; coordinata++){
          y[n_coordinate*pesce+coordinata] = input->x[n_coordinate*pesce+coordinata];
        }
      }//if 	
    }//for	
    int tmp = (int) input->x;
	input->x = y;
	y = (float *) tmp;
  }//if spostati >= rimasti	
  else{ 
    for (int pesce = 0; pesce < n_pesci; pesce++){
	  if(deltaf[pesce] != 0){
        for(int coordinata = 0; coordinata < n_coordinate; coordinata++){
		  input->x[n_coordinate*pesce+coordinata] = y[n_coordinate*pesce+coordinata];
        }
      }//if 	
    }//for	
  }//else
 ```
X: matrice coordinate correnti dei pesci 
Y: matrice coordinate dei pesci a seguito del movimento individuale 
Una volta eseguito il movimento individuale vengono spostati solo i pesci che 
hanno acquisito una posizione migliore (f_y < f_x>).

### Ottimizzazione
- spostati: numero di pesci spostati
- Inoltre, sappiamo che se deltaf del pesce i-esimo è pari a zero, allora il pesce non si è spostato.

Se la maggioranza dei pesci si sono spostati, la matrice y diventerà la nuova matrice x attraverso uno scambio di puntatori ed inoltre le coordinate dei pesci che non si spostano saranno copiate dal precedente vettore delle posizioni.

Altrimenti, se la maggioranza dei pesci non si spostano, verranno copiate in x solo i vettori posizione dei pesci spostati.

In una fase preliminare si era pensato di aggiornare il valore f_min ad ogni spostamento avendo a disposizione il valore di f corrente a seguito dello spostamento, confrontando il valore minimo corrente (memorizzato in una apposita variabile) con quest'ultimo, piuttosto che calcolarlo alla fine con un for, ma cio' risultava molto oneroso a causa della presenza di numerosi salti condizionati ripetuti per ciascuna iterazione. A tal fine si è deciso di calcolare il valore ottimo al termine delle iterazioni così da avere i medesimi salti condizionati per una unica funzione che itera sui pesci, invece che per ciascuna delle funzioni presenti e per ciascuna iterazione, così da ottenere una ottimizzazione del codice.