ligature
========

Outil qui permet de rechercher et remplacer dans un fichier ou un répertoire de 
fichiers une ligature, c’est-à-dire la fusion de deux ou trois caractères en un 
caractère unique, par la séquence de caractères correspondants. 

#### Liste des ligatures traitées

```
    Ligature	Équivalent		Code hexadécimal
       ﬀ            ff				 FB00
       ﬁ            fi				 FB01
       ﬂ            fl				 FB02
       ﬃ            ffi				FB03
       ﬄ            ffl				FB04
```

### Usage
```
    ligature.pl -r répertoire [ -e extension ]* [ -q ]
    ligature.pl -f fichier [ -q ]
    ligature.pl -h
```

### Options
```
   -e  indique la ou les extensions des fichiers à traiter dans le répertoire indiqué par l’option “-r”. 
       Dans le cas où on a plusieurs extensions, on peut répéter l’option ou donner la liste des extensions 
       séparées par des virgules.
   -f  indique le fichier à traiter.
   -h  affiche l’aide.
   -q  supprime les messages donnant le nombre de modifications réalisées pour chaque fichier.
   -r  indique le répertoire où se trouvent les fichiers à traiter.

```

### Exemple
```
    ligature.pl -r Corpus/Polaris -e txt -e ocr -q
    ligature.pl -r Corpus/Polaris -e txt,ocr -q
    ligature.pl -f Corpus/Polaris/ancien_0425.txt
```
