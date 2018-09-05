stat-corpus
===============

Outil de statistiques descriptives sur les corpus ISTEX extraits par **harvestCorpus.pl**

Permet de faire des statistiques sur les fichiers extraits d’ISTEX en utilisant le fichier 
de métadonnées `logRequete.txt` (cf. l’option `-v` du programme [`harvestCorpus.pl`](/scodex/harvest-corpus)) ou les
fichiers de métadonnées JSON correspondants aux documents extraits. 

Si les fichiers XML éditeurs ont été extraits, il permet aussi de vérifier s’ils ont ou non
les documents sous forme de texte structuré.

Le résultat peut être donné : 

 * soit avec une ligne par document et des champs séparés par des tabulations (format [TSV](https://fr.wikipedia.org/wiki/Tabulation-separated_values)) 
 ou des points-virgules (format [CSV](https://fr.wikipedia.org/wiki/Comma-separated_values)), la première ligne étant l’en-tête donnant la liste des 
 champs.  
 * soit au format [JSON](https://fr.wikipedia.org/wiki/JavaScript_Object_Notation) où les champs multivalués sont présentés sous forme de listes. 


### Usage
```
    statsCorpus.pl -l logfile -c fichier.corpus [ -r répertoireXML ] [ -s sortie ] 
                   [ -f (csv|json|tsv) ] [ -x (normal|lodex) ]
    statsCorpus.pl -m répertoireJSON [ -r répertoireXML ] [ -s sortie ] 
                   [ -f (csv|json|tsv) ] [ -x (normal|lodex) ]
    statsCorpus.pl -h
```

### Options
```
    -c  indique le nom du fichier “.corpus” généré par le programme “harvestCorpus.pl” 
        permettant de faire le lien entre l’identifiant ISTEX d’un document et le nom des 
        fichiers extraits correspondants.
    -f  indique le format de sortie, à savoir TSV (par défaut), CSV ou JSON.
    -h  affiche l’aide.
    -l  indique le nom du fichier “logfile” contenant les métadonnées ISTEX au format JSON
        créé par l’option “-v” du programme “harvestCorpus.pl”.
        Par défaut, ce fichier s’appelle “logRequete.txt” et se trouve dans le répertoire des
        fichiers déchargés depuis le serveur ISTEX.
    -m  indique le répertoire où se trouve les fichiers de métadonnées au format JSON déchargés
        par le programme “harvestCorpus.pl”.
    -r  indique le répertoire où se trouve les fichiers XML éditeurs obtenus à partir des
        fichiers ZIP déchargés par le programme “harvestCorpus.pl”. Si les fichiers XML sont
        dans le même répertoire que les fichiers JSON, l’option “-m” seule suffit.
    -s  indique le nom du fichier de sortie. Sinon, la sortie se fait sur la sortie standard. 
        Si l’extension du nom de fichier est “.csv”, “.json” ou “.tsv”, le format correspondant 
        sera utilisé sans avoir à le spécifier à l’aide de l’option “-f”.
    -x  étend la liste des champs affichés, soit en mode normal, soit en mode “lodex”, 
        c'est-à-dire avec un lien, affiché en exposant, entre auteurs et affiliations.
```

### Exemple

#### 1 - Liste originale

> Statistiques à partir du fichier `logRequete.txt` et du fichier `.corpus` correspondant, les fichiers XML éditeurs étant dans le répertoire `Arthropodes`. Le résultat, sur la sortie standard, est au format [**TSV**](https://fr.wikipedia.org/wiki/Tabulation-separated_values). 

```
    statsCorpus.pl -l Arthropodes/logRequete.txt -c Arthropodes_v2b.corpus -r Arthropodes
```

> Statistiques à partir des fichiers de métadonnées au format JSON extraits par `harvestCorpus.pl`  et présents dans le répertoire `Vieillissement` tout comme les fichiers XML éditeurs. Les deux commandes donnent le même résultat, ici dans le fichier `Vieil.tsv`, au format TSV. 

```
    statsCorpus.pl -m Vieillissement -r Vieillissement -s Vieil.tsv
    statsCorpus.pl -m Vieillissement -s Vieil.tsv
```

#### 2 - Liste étendue

> Même cas que prédédemment, mais avec une sortie au format [**CSV**](https://fr.wikipedia.org/wiki/Comma-separated_values) et une liste de champs adaptée à l’application [**Lodex**](http://lodex.inist.fr/). Si le résultat est le même avec ces deux commandes, le nom du fichier de sortie est lui différent, ce qui a permis de ne pas utiliser l’option `-f` pour avoir le format CSV dans le deuxième exemple. 

```
    statsCorpus.pl -m Vieillissement -s Vieil.txt -f csv -x lodex
    statsCorpus.pl -m Vieillissement -s Vieil.csv -x lodex
```

> Idem, mais avec une sortie au format [**JSON**](https://fr.wikipedia.org/wiki/JavaScript_Object_Notation). 

```
    statsCorpus.pl -m Vieillissement -s Vieil.txt -f json -x lodex
    statsCorpus.pl -m Vieillissement -s Vieil.json -x lodex
```

### Données extraites

#### 1 - Liste originale

Cette liste comprend, pour l’instant, 18 champs :

 * Identifiant ISTEX
 * Identifiant [ARK](https://api.istex.fr/documentation/ark/)
 * Nom de fichier
 * Éditeur
 * Score de qualité (donnée ISTEX)
 * Version PDF
 * XML structuré (“Oui”, “Non”, “Absent” ou “Indéterminé”)
 * Année de publication
 * Titre du document
 * Titre du périodique
 * ISSN
 * e-ISSN
 * Type de publication (par exemple “journal”)
 * Type de document (par exemple “research-article”)
 * Catégories Web of Science
 * Catégories Science-Metrix
 * Catégories Scopus
 * Catégories INIST

#### 2 - Liste étendue

À l'aide de l’option `-x lodex`, on peut étendre cette liste à 27 champs présentés dans un ordre différent pour les besoins de l’application [**Lodex**](http://lodex.inist.fr/) :

 * Nom de fichier
 * Titre du document
 * Auteur(s)
 * Affiliation(s)
 * Titre du périodique ou de la monographie
 * ISSN
 * e-ISSN
 * ISBN
 * e-ISBN
 * Éditeur
 * Type de publication (par exemple “journal”)
 * Type de document (par exemple “research-article”)
 * Année de publication
 * Langue(s) du document
 * Résumé
 * Mots-clés d'auteur
 * Catégories Web of Science
 * Catégories Science-Metrix
 * Catégories Scopus
 * Catégories INIST
 * Score de qualité (donnée ISTEX)
 * Version PDF
 * XML structuré (“Oui”, “Non”, “Absent” ou “Indéterminé”)
 * Identifiant ISTEX
 * Identifiant [ARK](https://api.istex.fr/documentation/ark/)
 * Identifiant [DOI](https://fr.wikipedia.org/wiki/Digital_Object_Identifier)
 * Identifiant PMID
