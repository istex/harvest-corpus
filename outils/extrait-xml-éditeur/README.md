extrait-xml-éditeur
===================

Outil qui permet d'extraire le fichier XML éditeur d’une archive ZIP et de le 
renommer pour lui donner la même racine que le document auquel il fait référence. 
Il travaille sur un fichier ou sur un répertoire de fichiers “.zip”. 
De plus, il permet de supprimer les fichiers “.zip” au fur et à mesure que les 
fichiers XML sont extraits pour libérer de l’espace disque.

**N.B. : certains cas problématiques ne sont toujours pas traités de façon adéquate et sont laissés à la charge de l’utilisateur. **

### Usage
```
    extraitXmlEditeur.pl -r répertoire [ -e expression_régulière ] [ -l log ] [ -s ]
    extraitXmlEditeur.pl -f fichier [ -e expression_régulière ] [ -l log ] [ -s ]
    extraitXmlEditeur.pl -h
```

### Options
```
    -e  indique l’expression régulière (compatible Perl) à utiliser pour identifier le 
        fichier XML éditeur dans l’archive “.zip” (à mettre entre simples ou doubles quotes)
    -f  indique le nom du fichier “.zip” contenant le fichier XML éditeur à extraire
    -h  affiche cette aide
    -l  indique le nom du fichier “log” recevant les messages d’erreur (ou autres) du programme 
        (N.B. : ce fichier n’est pas écrasé lorsque l’on relance le programme)
    -r  indique le répertoire où se trouve les fichiers “.zip” déchargés par le programme 
        “harvestCorpus.pl” et d’où doivent être extraits les fichiers XML éditeurs.
    -s  supprime le fichier “.zip” si le fichier XML a été extrait avec succès.
```

### Exemples
```
   extraitXmlEditeur.pl -r Arthopodes -l logExtraitXml.txt
   extraitXmlEditeur.pl -f Arthropodes/arthropodes_000125.zip -e '\.article'

```
