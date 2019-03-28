harvest-corpus
===============

Outil d’extraction de corpus ISTEX

Permet de décharger un corpus de fichiers textes (PDF, [TEI](https://fr.wikipedia.org/wiki/Text_Encoding_Initiative), TXT), de fichiers de 
métadonnées ([JSON](https://fr.wikipedia.org/wiki/JavaScript_Object_Notation), [MODS](https://fr.wikipedia.org/wiki/Metadata_Object_Description_Schema), XML) ou de fichiers d’enrichissement depuis la base ISTEX 
à partir d’une requête ou d’un fichier [`.corpus`](#1---fichier-). Permet également de renommer les 
fichiers déchargés et de générer un fichier de notices bibliographiques. 

Il est possible d’avoir ce programme, ainsi que les utilitaires présents dans le répertoire “outils”, sous forme d’une image [Docker](#docker).


### Prérequis

Le programme `harvestCorpus.pl` fonctionne sous Unix/Linux ainsi qu’avec Cygwin 
sous Windows. Il utilise plusieurs modules dont la plupart sont présents dans la 
distribution standard de **Perl**. Normalement, les seuls modules à installer sont :
 - HTTP::CookieJar::LWP
 - JSON
 - URI::Encode


### Usage
```
    harvestCorpus.pl -o 'requête'
    harvestCorpus.pl -q 'requête' [ -a | -emt <type de fichier>[,<type de fichier>]* ]
                     [ -d destination ] [ -n [notices.txt]] [ -p préfixe ] [ -s fichier.corpus ]
                     [ -l nombre ] [ -r [nombre]] [ -iv ] [ -j jeton ]  [ -z [gzip|bzip2]]
    harvestCorpus.pl -c fichier.corpus ( -a | -emt <type de fichier>[,<type de fichier>]* )
                     [ -d destination ] [ -n [notices.txt]] [ -p préfixe ] [ -l nombre ]
                     [ -f nombre ] [ -j jeton ]  [ -z [gzip|bzip2]]
    harvestCorpus.pl -h
```


### Options
```
   -a  télécharge tous les fichiers correspondants aux documents
   -c  utilise le fichier “fichier.corpus” comme source d’identifiants pour télécharger
       les documents (incompatible avec les options “-r” et “-s”)
   -d  indique le répertoire de destination des documents (répertoire courant par défaut)
   -h  affiche cette aide
   -e  liste les enrichissements à télécharger, soit “all” pour l’ensemble, soit
       “abesAuthors”, “abesSubjects”, “multicat”, “nb”, “refBibs”, “teeft” ou “unitex”
   -f  indique à partir de quel numéro de document, on télécharge les fichiers, mais
       seulement avec l’option “-c”. 
       ATTENTION : numérotation informatique qui commence à “0”. Pour avoir les fichiers 
       à partir du document n° “50 001”, utiliser la valeur “50 000” !
   -i  utilise l’identifiant ISTEX à la place de l’identifiant ARK dans le fichier
       “fichier.corpus”
   -j  indique le jeton d’authentification obtenu sur “https://api.istex.fr/token/”
   -l  limite le nombre maximum de documents téléchargés au nombre fourni en argument
   -m  liste les fichiers de métadonnées à télécharger, soit “all” pour l’ensemble,
       soit “json”, “mods” ou “xml”
   -n  crée un fichier de notices bibliographiques (sans argument, crée le fichier
       “notices.txt” dans le répertoire courant ou celui donné par l’option “-d”)
   -o  indique la requête à tester, entre simples quotes en présence de blancs ou de
       caractères spéciaux, et simplement retourne le nombre de documents attendus ou
       un message d’erreur
   -p  indique le préfixe utilisé pour renommer les fichiers téléchargés (par défaut, “f”).
       Ce préfixe est ensuite suivi d’un numéro séquentiel et de l’extension correspondant
       au type de document téléchargé. Si la valeur de l’option “-p” est “0” (le chiffre, 
       pas la lettre majuscule), alors le fichier garde son nom original, c’est-à-dire 
       l’identifiant ISTEX
   -q  indique la requête à utiliser, entre simples quotes en présence de blancs ou de
       caractères spéciaux (incompatible avec l’option “-c”)
   -r  provoque une sortie dans un ordre aléatoire en fonction d’une “graine” aléatoire
       si l’argument est absent ou égal à 0, ou en fonction du nombre entier positif non nul
       fourni en argument (incompatible avec l’option “-c” et limité à 10.000 documents)
   -s  indique le nom du fichier “.corpus” généré. Par défaut, génère le fichier
       “notices.corpus” ou “préfixe.corpus” (cf. option “-p”) dans le répertoire courant
       ou celui donné par l’option “-d” (incompatible avec l’option “-c”)
   -t  liste les fichiers de texte intégral à télécharger, soit “all” pour l’ensemble,
       soit “ocr”, “pdf”, “tei”, “txt” ou “zip”
   -v  garde les métadonnées ISTEX au format JSON dans un fichier “logRequete.txt” dans
       le répertoire courant ou celui donné par l’option “-d”
   -z  indique le nom du programme à utiliser pour compresser les fichiers générés,
       à savoir “logRequete.txt”, “id.corpus”, “notices.txt” ou équivalents. Par
       défaut, utilise “gzip”
```


### Authentification

Le téléchargement de certains fichiers, notamment le texte intégral, à partir d’ISTEX n’est autorisé qu’aux membres de l’ESR (**E**nseignement **S**upérieur et **R**echerche). Si vous n’avez pas une authentification par adresse IP, il vous faut obtenir un jeton d’accès à l’adresse “**[https://api.istex.fr/token/](https://api.istex.fr/token/)**”. Après avoir sélectionné votre organisme de tutelle et vous être identifié, vous serez dirigé vers une page au format JSON contenant deux “clés” :
 - “*_comment*” : indication sur l’emploi du jeton d’accès (à ne pas suivre dans le cas présent), 
 - “*_accessToken*” : donnant le jeton d’accès à utiliser avec l’option `-j`.


### Exemples

Par souci de clarté, on suppose dans les exemples suivants ne pas avoir besoin de l’option `-j` et du jeton d’accès qui est d’une taille non négligeable. 

#### 1 - Requête simple

> Téléchargement des fichiers PDF et TEI des articles de la revue “**Biofutur**” dans le répertoire 
> “**FichiersPDF**” en les renommant avec le préfixe “**biofutur**” tout en créant un fichier **`Biofutur.corpus`** 
> et en conservant les réponses de l’API ISTEX :

```bash
   harvestCorpus.pl -q '(host.title:"Biofutur" OR host.issn:"0294-3506")' -t pdf,tei -d FichiersPDF -s Biofutur.corpus -p biofutur -v
```

#### 2 - Utilisation du fichier `.corpus`

> À l’aide du fichier “**Biofutur.corpus**” ainsi créé, téléchargement dans le répertoire “**Metadata**” 
> des métadonnées au format **Mods** correspondants aux fichiers téléchargés précédemment :

```bash
   harvestCorpus.pl -c Biofutur.corpus -m mods -d Metadata
```

> Téléchargement dans le répertoire “**FichiersTEI**” des fichiers **TEI** par paquet de 25 000 à partir du fichier **`Elsevier/els.corpus`** contenant les identifiants de tous les documents issus d’Elsevier :

```bash
   harvestCorpus.pl -c Elsevier/els.corpus -t tei -d FichiersTEI -l 25000
   harvestCorpus.pl -c Elsevier/els.corpus -t tei -d FichiersTEI -l 25000 -f 25000
   harvestCorpus.pl -c Elsevier/els.corpus -t tei -d FichiersTEI -l 25000 -f 50000
   ...
```

#### 3 - Tirage aléatoire

> Création d’un échantillon de 1000 fichiers textes provenant d’Elsevier, choisi de façon aléatoire, et génération du fichier **`Elsevier/els.corpus`** et du fichier de notices bibliographiques **`Elsevier/els.txt`** :

```bash
   harvestCorpus.pl -q corpusName:elsevier -t txt,ocr -d Elsevier -p els -n -l 1000 -r 
```


### Fichiers générés par `harvestCorpus.pl`

#### 1 - Fichier `.corpus`

Le programme génère un fichier contenant des informations sur le corpus, comme la requête utilisée, la date de création et le nombre de documents obtenus. Après ces métadonnées, on trouve une ligne avec l’indication `[ISTEX]` suivi de l’identifiant de chaque document, un par ligne, sous la forme d’un type d’identifiant, `ark` ou `id`, suivi de sa valeur. En commentaire, on peut également trouver le nom du fichier correspondant (sans l’extension qui dépend du type de fichier téléchargé). 

Par défaut, ce fichier se nomme `id.corpus` ou `préfixe.corpus` en présence de l’option `-p` et il se trouve soit dans le répertoire courant, soit dans le répertoire indiqué par l’option `-d`.

Le texte ci-dessous correspond au début du fichier **`Elsevier/els.corpus`** obtenu avec l’exemple “[3 - Tirage aléatoire](#3---tirage-aléatoire)”.

```text
#
# Fichier .corpus
#
title        : <à compléter> 
author       : BESAGNI
publisher    : <à compléter> 
query        : corpusName:elsevier
date         : Mardi 6 Mars 2018 09:52:50
license      : CC-By ?
versionInfo  : 1.0 ?
randomSeed   : 1520326370561
total        : 1000 / 6015985 documents

[ISTEX]
ark ark:/67375/6H6-WVMBX405-F                  # els00001
ark ark:/67375/6H6-B8WM60RB-M                  # els00002
ark ark:/67375/6H6-ZL2X5PWP-B                  # els00003
ark ark:/67375/6H6-GSLCZHZG-R                  # els00004
ark ark:/67375/6H6-BZZDVT14-P                  # els00005
ark ark:/67375/6H6-SC5QFP5J-0                  # els00006
...
```

Avec l’option `-i`, la même commande aurait donné le fichier **`Elsevier/els.corpus`** suivant :

```text
#
# Fichier .corpus
#
title        : <à compléter> 
author       : BESAGNI
publisher    : <à compléter> 
query        : corpusName:elsevier
date         : Mardi 6 Mars 2018 09:52:50
license      : CC-By ?
versionInfo  : 1.0 ?
randomSeed   : 1520326370561
total        : 1000 / 6015985 documents

[ISTEX]
id  0ACFDDBB83BF9A5ABAD34686AC4C8CE9317BDB2E    # els00001
id  742E33D5C0485C08A9CDE3425557F8B28B81A0D3    # els00002
id  001199848185C5FF5B9E98701DD619C43676D84E    # els00003
id  639E8121432DECC831D632BF35C3BE8245CAF309    # els00004
id  90F958B4490A91E16E673FA96C0503604A9295E6    # els00005
id  CF9E6012BD4F0F15F34B87C4F65DF4E43D7A3621    # els00006
...
```

#### 2 - Fichier `logRequete.txt`

Avec l’option `-v`, il est possible de conserver l’ensemble des métadonnées au format JSON envoyées par l’API ISTEX lors de l’exécution d’une requête. Ces métadonnées sont conservées dans le fichier `logRequete.txt` qui se trouve soit dans le répertoire courant, soit dans le répertoire indiqué par l’option `-d`. 

Ce fichier est notamment utilisé par le programme [`statsCorpus.pl`](../../tree/master/outils/stats-corpus) pour extraire les principales informations concernant chaque document du corpus, comme le titre, le nom du périodique, la date de publication, l’éditeur, la version de PDF, etc. 

#### 3 - Fichier de notices bibliographiques

Avec l’option `-n`, le programme génère un fichier de notices bibliographiques qui donne une vision synthétique du corpus dans un format familier aux documentalistes. Si l’option `-n` n’a pas d’argument, le fichier s’appelle `notices.txt` et il se trouve soit dans le répertoire courant, soit dans le répertoire indiqué par l’option `-d`. 

L’exemple ci-dessous correspond au début du fichier `Elsevier/els.txt` généré avec l’exemple “[3 - Tirage aléatoire](#3---tirage-aléatoire)” et la première notice est celle du fichier “els00001” du fichier `Elsevier/els.corpus` donné en exemple. 

```text
#
# Requête : "corpusName:elsevier"
#
# Nombre de réponses : 1000 / 6015985
#

1/1000
NO : ISTEX ark:/67375/6H6-WVMBX405-F (corpus Elsevier)
TI : Genesis of complex deformation on the slopes of the Drina river
DT : Journal ; Abstract
SO : International Journal of Rock Mechanics and Mining Sciences and 
     Geomechanics Abstracts ; ISSN 0148-9062 ; 1992 ; vol. 29 ; n° 3 ; p. A191
LA : Anglais
LO : PII 0148-9062(92)94075-3 ; DOI 10.1016/0148-9062(92)94075-3
   
...
```

### Docker

Pour construire une image Docker, faire :

```
   docker build -t istex/corpus .
```

Dans l’exemple suivant, on utilise `harvestCorpus.pl` à partir de son image Docker dans le cas où on veut télécharger des métadonnées à l’aide d’un fichier `.corpus` en supposant que :

* l’utilisateur à l’identifiant (ou [UID](https://fr.wikipedia.org/wiki/User_identifier)) 1002
* l’utilisateur à l’identifiant de groupe (ou [GID](https://fr.wikipedia.org/wiki/Groupe_%28Unix%29)) 400
* le fichier `.corpus` s’appelle “**exemple.corpus**”
* le répertoire devant recevoir les fichiers téléchargés s’appelle “**Metadata**”
* et le fichier `.corpus` comme le répertoire sont dans le répertoire courant

```
   docker run --rm -u 1002:400 -v `pwd`:/tmp istex/corpus harvestCorpus -c exemple.corpus -m json,mods -d Metadata
```

À noter que les programmes dans cette image Docker, comme défini dans le fichier “**Dockerfile**”, n'ont pas d’extension `.pl`.
