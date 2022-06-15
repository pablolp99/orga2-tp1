#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <math.h>

#include "lib.h"

int main (void){    
    FILE* pfile = fopen("salida.propios.caso3.txt","a");

    card_t* card;
    char* suit;
    int32_t number;

    fprintf(pfile, "== Game Array ==\n");

    array_t* cardDeckArray = arrayNew(TypeCard, 5);

    //Creo 5 cartas, las agrego al mazo y libero la memoria
    suit = "basto"; number = 1; card = cardNew(suit, &number); arrayAddLast(cardDeckArray, card); cardDelete(card);
    suit = "espada"; number = 2; card = cardNew(suit, &number); arrayAddLast(cardDeckArray, card); cardDelete(card);
    suit = "copa";   number = 3; card = cardNew(suit, &number); arrayAddLast(cardDeckArray, card); cardDelete(card);
    suit = "oro";    number = 4; card = cardNew(suit, &number); arrayAddLast(cardDeckArray, card); cardDelete(card);
    suit = "espada"; number = 5; card = cardNew(suit, &number); arrayAddLast(cardDeckArray, card); cardDelete(card);

    arrayPrint(cardDeckArray, pfile); fprintf(pfile, "\n");
    
    //Apilo la carta 1 en la carta 3
    card_t* a = arrayGet(cardDeckArray, 3);
    card_t* removed = arrayRemove(cardDeckArray,1);
    cardAddStacked(a,removed);
    cardDelete(removed);
    
    arrayPrint(cardDeckArray, pfile); fprintf(pfile, "\n\n");

    arrayDelete(cardDeckArray);

    fprintf(pfile, "== Game List ==\n");

    list_t* cardDeckList = listNew(TypeCard);

    //Creo 5 cartas, las agrego al mazo y libero la memoria
    suit = "basto"; number = 1; card = cardNew(suit, &number); listAddLast(cardDeckList, card); cardDelete(card);
    suit = "espada"; number = 2; card = cardNew(suit, &number); listAddLast(cardDeckList, card); cardDelete(card);
    suit = "copa";   number = 3; card = cardNew(suit, &number); listAddLast(cardDeckList, card); cardDelete(card);
    suit = "oro";    number = 4; card = cardNew(suit, &number); listAddLast(cardDeckList, card); cardDelete(card);
    suit = "espada"; number = 5; card = cardNew(suit, &number); listAddLast(cardDeckList, card); cardDelete(card);

    listPrint(cardDeckList, pfile); fprintf(pfile, "\n");
    
    //Apilo la carta 1 en la carta 3
    a = listGet(cardDeckList, 3);
    removed = listRemove(cardDeckList,1);
    cardAddStacked(a,removed);
    cardDelete(removed);
    
    listPrint(cardDeckList, pfile); fprintf(pfile, "\n");

    listDelete(cardDeckList);

    fclose(pfile);
    return 0;
}


