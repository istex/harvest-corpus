#!/usr/bin/env perl


# Déclaration des pragmas
use strict;
use utf8;
use open qw/:std :utf8/;

# Appel des modules externes de base
use Encode qw(decode_utf8 encode_utf8 is_utf8);
use Getopt::Long;

# Appel des modules spécifiques à l'application
use JSON;

my ($programme) = $0 =~ m|^(?:.*/)?(.+)|;
my $substitut = " " x length($programme);

my $usage = "Usage : \n" .
            "    $programme -l logfile -c fichier.corpus [ -r répertoire_XML ] [ -s sortie ] \n" .
            "    $substitut [ -f (csv|json|tsv) ] [ -x (normal|lodex) ] \n" .
            "    $programme -m répertoire_JSON [ -r répertoire_XML ] [ -s sortie ] \n" .
            "    $substitut [ -f (csv|json|tsv) ] [ -x (normal|lodex) ] \n".
            "    $programme -h \n";

my $version   = "3.7.1";
my $dateModif = "24 Janvier 2019";

# Variables pour les options
my $aide        = 0;
my $corpus      = "";
my $logfile     = "";
my $metadata    = "";
my $prefixe     = "";
my $repertoire  = "";
my $sortie      = "";
my $type        = "";
my $xtended     = "";

eval        {
        $SIG{__WARN__} = sub {usage(1);};
        GetOptions(
                "corpus=s"      => \$corpus,
                "format=s"      => \$type,
                "help"          => \$aide,
                "logfile=s"     => \$logfile,
                "metadonnees=s" => \$metadata,
                "prefixe=s"     => \$prefixe,
                "repertoire=s"  => \$repertoire,
                "sortie=s"      => \$sortie,
                "xtended=s"     => \$xtended,
                );
        };
$SIG{__WARN__} = sub {warn $_[0];};

if ( $aide ) {
        print "Programme : \n";
        print "    “$programme”, version $version ($dateModif)\n";
        print "    Permet de faire des statistiques sur les fichiers extraits d’ISTEX en utilisant le fichier \n";
        print "    de métadonnées “logRequete.txt” (cf. l’option “-v” du programme “harvestCorpus.pl”) ou les \n";
        print "    fichiers de métadonnées JSON correspondants aux documents extraits. \n";
        print "    Si les fichiers XML éditeurs ont été extraits, il permet aussi de vérifier s’ils ont ou non \n";
        print "    les documents sous forme de texte structuré. \n";
        print "\n";
        print $usage;
        print "\nOptions : \n";
        print "    -c  indique le nom du fichier “.corpus” généré par le programme “harvestCorpus.pl” permettant \n";
        print "        de faire le lien entre l’identifiant ISTEX ou ARK d’un document et le nom des fichiers \n";
        print "        extraits correspondants.\n";
        print "    -f  indique le format de sortie, à savoir TSV (par défaut), CSV ou JSON. \n";
        print "    -h  affiche cette aide. \n";
        print "    -l  indique le nom du fichier “logfile” contenant les métadonnées ISTEX au format JSON \n";
        print "        créé par l’option “-v” du programme “harvestCorpus.pl”. Par défaut, ce fichier \n";
        print "        s’appelle “logRequete.txt” et se trouve dans le répertoire des fichiers déchargés \n";
        print "        depuis le serveur ISTEX. \n";
        print "    -m  indique le répertoire où se trouve les fichiers de métadonnées au format JSON déchargés \n";
        print "        par le programme “harvestCorpus.pl” (what else?).\n";
        print "    -r  indique le répertoire où se trouve les fichiers XML éditeurs obtenus à partir des \n";
        print "        fichiers ZIP déchargés par le programme “harvestCorpus.pl”. Si les fichiers XML sont \n";
        print "        dans le même répertoire que les fichiers JSON, l’option “-m” seule suffit. \n";
        print "    -s  indique le nom du fichier de sortie. Sinon, la sortie se fait sur la sortie standard. \n";
        print "        Si l'extension du fichier de sortie est “.csv”, “.json” ou “.tsv”, le format correspondant \n";
        print "        est utilisé. \n";
        print "    -x  étend la liste des champs affichés, soit en mode normal, soit en mode “lodex”, \n";
        print "        c'est-à-dire avec un lien, affiché en exposant, entre auteurs et affiliations. \n";
        print "\nExemples : \n";
        print "    $programme -l Arthropodes/logRequete.txt -c Arthropodes_v2b.corpus -r Arthropodes\n";
        print "    $programme -m Vieillissement -r Vieillissement -s Vieil.tsv \n";
        print "    $programme -m Vieillissement -s Vieil.tsv                     (identique au précédent)\n";
        print "    $programme -m Vieillissement -s Vieil.txt -f csv -x lodex     (en CSV, prêt pour Lodex)\n";
        print "    $programme -m Vieillissement -s Vieil.csv -x lodex            (idem)\n";
        print " \n";

        exit 0;
        }

# Premier test sur la présence des options obligatoires
usage(2) if $logfile and not $corpus;
usage(2) if $corpus and not $logfile;
usage(2) if not $logfile and not $metadata;
if ( $metadata and not -d $metadata ) {
        print STDERR "$programme : le répertoire \"$metadata\" n’existe pas !\n";
        exit 3;
        }

# Test sur le format de sortie
if ( $type ) {
        if ( $type !~ /^(csv|json|tsv)\z/oi ) {
                print STDERR "$programme : le format de fichier \"$type\" n’est pas correct !\n";
                usage(4);
                }
        $type = lc($type);
        }

# Test de l’existence d’un nom de fichier de sortie  
# et de son extension avant ouverture de celui-ci
if ( $sortie ) {
        if ( $sortie =~ /\.(csv|json|tsv)\z/oi ) {
                my $tmp = lc($1);
                if ( $type and $type ne $tmp ) {
                        print STDERR "$programme : le format \"$type\" et l’extension \"$tmp\" ne sont pas compatible !\n";
                        exit 5;
                        }
                $type = $tmp;
                }
        open(OUT, ">:utf8", $sortie) or die "\"$sortie\" : $!,";
        }
# Ou bien, renvoi sur la sortie standard
else    {
        open(OUT, ">&STDOUT") or die "$!,";
        binmode(OUT, ":utf8");
        }

$type = "tsv" if not $type;

if ( $xtended ) {
        if ( $xtended !~ /^(normal|lodex)\z/oi ) {
                print STDERR "$programme : mauvais argument pour l’option “-x” !\n";
                usage(6);
                }
        $xtended = lc ($xtended);
        }

# Autres variables globales
my $entete = "";
my $format = "";
my $json   = "";
my $nbDocs = 0;
my $num    = 0;
my $racine = "";
my $total  = 0;
my @champs = ();
my %racine = ();

# Verbalisation des codes langues ISO 639-2
my %langue = langues();

# Liste des noms des éditeurs
my %nom = (
        "elsevier"           => "Elsevier",
        "wiley"              => "Wiley",
        "springer-journals"  => "Springer (journals)",
        "oup"                => "OUP",
        "cambridge"          => "Cambridge",
        "sage"               => "Sage",
        "bmj"                => "BMJ",
        "springer-ebooks"    => "Springer (e-books)",
        "iop"                => "IOP",
        "nature"             => "Nature",
        "rsc-journals"       => "RSC (journals)",
        "degruyter-journals" => "Degruyter (journals)",
        "ecco"               => "ECCO",
        "edp-sciences"       => "EDP Sciences",
        "emerald"            => "Emerald",
        "brill-journals"     => "Brill (journals)",
        "eebo"               => "EEBO",
        "brepols-journals"   => "Brepols",
        "rsc-ebooks"         => "RSC (e-books)",
        "brill-hacco"        => "Brill HACCO",
        "gsl"                => "GSL",
        "numerique-premium"  => "Numérique Premium",
        );

# Liste des outils utilisés pour générer les catégories
my %outil = (
        "Catégories WoS"            => "multicat", 
        "Catégories Science-Metrix" => "multicat", 
        "Catégories Scopus"         => "multicat", 
        "Catégories INIST"          => "nb",
        );

# Liste des catégories WoS de niveau 1
my %generique = (
        "arts and humanities" => 1,
        "science" => 1,
        "social science" => 1,
        );

if ( $xtended eq 'lodex' ) {
        @champs = ("Nom de fichier", "Titre", "Auteur(s)", "Affiliation(s)", 
                   "Revue ou monographie", "ISSN", "e-ISSN", "ISBN", "e-ISBN", 
                   "Éditeur", "Type de publication", "Type de document", 
                   "Date de publication", "Langue(s) du document", "Résumé", 
                   "Mots-clés d’auteur", "Catégories WoS", "Catégories Science-Metrix", 
                   "Catégories Scopus", "Catégories INIST", "Score qualité", 
                   "Version PDF", "XML structuré", "Identifiant ISTEX", "ARK", 
                   "DOI", "PMID");
        }
else    {
        @champs = ("Identifiant ISTEX", "ARK", "Nom de fichier", "Éditeur", 
                   "Score qualité", "Version PDF", "XML structuré", 
                   "Date de publication", "Titre", "Revue", "ISSN", 
                   "e-ISSN", "Type de publication", "Type de document", 
                   "Catégories WoS", "Catégories Science-Metrix", 
                   "Catégories Scopus", "Catégories INIST");
        }

# Liste des champs à traiter en champs JSON simples pour Lodex 
my %simple = (
        "Type de publication" => 1,
        "Type de document"    => 1,
        "PMID"                => 1,
        "DOI"                 => 1,
        "ISSN"                => 1,
        "e-ISSN"              => 1,
        "ISBN"                => 1,
        "e-ISBN"              => 1,
        );

my $entete = join("\t", @champs);
if ( $type eq "csv" ) {
        print OUT "\x{FEFF}" . tsv2csv($entete) . "\n";
        }
elsif ( $type eq "tsv" ) {
        print OUT "\x{FEFF}$entete\n";
        }

if ( $logfile ) {
        # Lecture du fichier “.corpus” ...
        if ( not -f $corpus ) {
                print STDERR "Erreur : fichier \"$corpus\" absent\n";
                exit 14;
                }
        elsif ( $corpus =~ /\.g?[zZ]\z/ ) {
                open(TAB, "gzip -cd $corpus |") or 
                        die "Erreur : Impossible d'ouvrir \"$corpus\" : $!,";
                binmode(TAB, ":utf8");
                }
        elsif ( $corpus =~ /\.bz2\z/ ) {
                open(TAB, "bzip2 -cd $corpus |") or 
                        die "Erreur : Impossible d'ouvrir \"$corpus\" : $!,";
                binmode(TAB, ":utf8");
                }
        else    {
                open(TAB, "<:utf8", $corpus) or 
                        die "Erreur : Impossible d'ouvrir \"$corpus\" : $!,";
                }
        my $nbIds = 0;
        while(<TAB>) {
                if ( m|^total +: (\d+) (/ \d+ )?documents|o ) {
                        $nbDocs = $1;
                        }
                if ( /^(ark|id) /o ) {
                        chomp;
                        $nbIds ++;
                        s/\r//go;        # Au cas où ...
                        my ($type, $id, $com, $nom) = split(/\s+/);
                        if ( $type eq 'ark' and $id !~ /^ark:/o ) {
                                $id = "ark:$id";
                                }
                        $racine{$id} = $nom;
                        }
                }
        close TAB;
        if (  not $nbDocs and $nbIds ) {
                $nbDocs = $nbIds
                }
        if ( $type eq 'json' ) {
                print OUT "{\n  \"total\": $nbDocs,\n  \"data\": [\n";
                }

        # ... avant la lecture du fichier “logRequete”
        if ( not -f $logfile ) {
                print STDERR "Erreur : fichier \"$logfile\" absent\n";
                exit 14;
                }
        elsif ( $logfile =~ /\.g?[zZ]\z/ ) {
                open(INP, "gzip -cd $logfile |") or 
                        die "Erreur : Impossible d'ouvrir \"$logfile\" : $!,";
                binmode(INP, ":raw");
                }
        elsif ( $logfile =~ /\.bz2\z/ ) {
                open(INP, "bzip2 -cd $logfile |") or 
                        die "Erreur : Impossible d'ouvrir \"$logfile\" : $!,";
                binmode(INP, ":raw");
                }
        else    {
                open(INP, "<:raw", $logfile) or 
                        die "Erreur : Impossible d'ouvrir \"$logfile\" : $!,";
                }
        while(<INP>) {
                if ( /^# (\w+_?\d+)/ ) {
                        $racine = $1;
                        next;
                        }
                elsif ( /^#/ ) {
                        next;
                        }
                $json .= $_;
                if ( /^\}/o ) {
                        my $perl = decode_json $json;
                        my %top = %{$perl};
                        if ( defined $top{'total'} ) {
                                $total = $top{'total'};
                                if ( $total > 0 ) {
                                        $format = sprintf("%%0%dd", length($total) + 1);
                                        }
                                }
                        if ( defined $top{'hits'} ) {
                                my @hits = @{$top{'hits'}};
                                foreach my $hit (@hits) {
                                        traite($hit);
                                        }
                                }
                        else    {
                                traite($perl);
                                }
                        $json = "";
                        }
                }
        }
elsif ( $metadata ) {
        opendir(DIR, $metadata) or die "$!,";
        my @fichiers = sort grep(/\.json$/, readdir DIR);
        closedir DIR;

        $nbDocs = $#fichiers + 1;
        if ( $type eq 'json' ) {
                print OUT "{\n  \"total\": $nbDocs,\n  \"data\": [\n";
                }

        foreach my $fichier (@fichiers) {
                ($racine) = $fichier =~ /^(.+)\.json\z/o;
                open(JSN, "<:raw", "$metadata/$fichier") or die "$!,";
                while(<JSN>) {
                        $json .= $_;
                        if ( /^\}/o ) {
                                my $perl = decode_json $json;
                                traite($perl);
                                $json = "";
                                }
                        }
                close JSN;
                }
        }
if ( $type eq 'json' ) {
        print OUT "  ]\n}\n";
        }
close OUT;


exit 0;


sub usage
{
print STDERR $usage;

exit shift;
}

sub traite
{
my $ref = shift;

$num ++;
my $fichier = undef;
my $xml     = undef;
my @valeurs = ();
my %hit = %{$ref};
my $id = $hit{'id'};
my $ark = $hit{'arkIstex'};
if ( $racine ) {
        $fichier = $racine;
        $racine = "";
        }
elsif ( $racine{$ark} ) {
        $fichier = $racine{$ark};
        }
elsif ( $racine{$id} ) {
        $fichier = $racine{$id};
        }
elsif ( $prefixe ) {
        $fichier = "$prefixe" . sprintf($format, $num);
        }
if ( defined $fichier ) {
        if ( $repertoire ) {
                $xml = "$repertoire/$fichier.xml";
                }
        elsif ( $metadata ) {
                $xml = "$metadata/$fichier.xml";
                }
        }
else    {
        $fichier = "Nom de fichier inconnu";
        }
my $titre = $hit{'title'};
my $corpusName = $hit{'corpusName'};
my $nom = $corpusName;
if ( $nom{$nom} ) {
        $nom = $nom{$nom};
        }

# À REVOIR !!!
my $date = "";
my $copyrightDate   = "";
my $publicationDate = "";

if ( $hit{'copyrightDate'} ) {
        $copyrightDate = $hit{'copyrightDate'};
        }
if ( $hit{'publicationDate'} ) {
        $publicationDate = $hit{'publicationDate'};
        }
if ( $copyrightDate and $publicationDate ) {
        if ( $copyrightDate == $publicationDate ) {
                $date = $copyrightDate;
                }
        elsif ( $copyrightDate =~ /^[12]\d\d\d\z/o ) {
                $date = $copyrightDate;
                }
        else    {
                $date = $publicationDate;
                }
        }
elsif ( $copyrightDate ) {
        $date = $copyrightDate;
        }
elsif ( $publicationDate ) {
        $date = $publicationDate;
        }
else    {
        $date = "S.D.";
        }


my $langues = "";
if ( defined $hit{'language'} ) {
        $langues = join(" ; ", @{$hit{'language'}}) if $type ne 'json';
        $langues = \@{$hit{'language'}} if $type eq 'json';
        }
elsif ( $type eq 'json' ) {
        $langues = [];
        }
my $wos           = "";
my $scienceMetrix = "";
my $scopus        = "";
my $inist         = "";
if ( $type eq 'json' ) {
        $wos           = [];
        $scienceMetrix = [];
        $scopus        = [];
        $inist         = [];
        }
if ( defined $hit{'categories'} ) {
        my %categories = %{$hit{'categories'}};
        if ( defined $categories{'wos'} ) {
                $wos = categories($categories{'wos'});
                }
        if ( defined $categories{'scienceMetrix'} ) {
                $scienceMetrix = categories($categories{'scienceMetrix'});
                }
        if ( defined $categories{'scopus'} ) {
                $scopus = categories($categories{'scopus'});
                }
        if ( defined $categories{'inist'} ) {
                $inist = categories($categories{'inist'});
                }
        }
my $genre = "";
if ( defined $hit{'genre'} ) {
        $genre = join(", ", @{$hit{'genre'}}) if $type ne 'json';
        $genre = \@{$hit{'genre'}} if $type eq 'json';
        }
elsif ( $type eq 'json' ) {
        $genre = [];
        }
my $pdfVersion = "";
my $score = "";
if ( defined $hit{'qualityIndicators'} ) {
        my %indicateurs = %{$hit{'qualityIndicators'}};
        if ( defined $indicateurs{'pdfVersion'} ) {
                $pdfVersion = $indicateurs{'pdfVersion'};
                }
        if ( defined $indicateurs{'score'} ) {
                $score = $indicateurs{'score'};
                }
        }
my $revue = "";
my $isbn  = "";
my $eisbn = "";
my $issn  = "";
my $eissn = "";
my $dt    = "";
if ( defined $hit{'host'} ) {
        my %host = %{$hit{'host'}};
        if ( defined $host{'title'} ) {
                $revue = $host{'title'}
                }
        if ( defined $host{'isbn'} ) {
                $isbn = join("/", @{$host{'isbn'}}) if $type ne 'json';
                $isbn = \@{$host{'isbn'}} if $type eq 'json';
                }
        elsif ( $type eq 'json' ) {
                $isbn = [];
                }
        if ( defined $host{'eisbn'} ) {
                $eisbn = join("/", @{$host{'eisbn'}}) if $type ne 'json';
                $eisbn = \@{$host{'eisbn'}} if $type eq 'json';
                }
        elsif ( $type eq 'json' ) {
                $eisbn = [];
                }
        if ( defined $host{'issn'} ) {
                $issn = join("/", @{$host{'issn'}}) if $type ne 'json';
                $issn = \@{$host{'issn'}} if $type eq 'json';
                }
        elsif ( $type eq 'json' ) {
                $issn = [];
                }
        if ( defined $host{'eissn'} ) {
                $eissn = join("/", @{$host{'eissn'}}) if $type ne 'json';
                $eissn = \@{$host{'eissn'}} if $type eq 'json';
                }
        elsif ( $type eq 'json' ) {
                $eissn = [];
                }
        if ( defined $host{'genre'} ) {
                $dt = join(", ", @{$host{'genre'}}) if $type ne 'json';
                $dt = \@{$host{'genre'}} if $type eq 'json';
                }
        elsif ( $type eq 'json' ) {
                $dt = [];
                }
        }
my $structure = "Absent";
if ( defined $xml and -f $xml ) {
        $structure = "Non";
        my $texte = "";
        my $encoding = undef;
        open(XML, "<:utf8", $xml) or die "$!,";
        while(<XML>) {
                if ( m|<\?[^>]+\bencoding *= *(["'])(.+?)\1[^>]*>|o and not defined $encoding ) {
                        $encoding = $2;
                        close XML;
                        $texte = "";
                        open(XML, "<:encoding($encoding)", $xml) or die "$!,";
                        next;
                        }
                tr/\n\r/ /s;
                $texte .= $_;
                }
        close XML;
        if ( $corpusName eq 'bmj' or
             $corpusName =~ /^brill-/o or
             $corpusName eq 'cambridge' or
             $corpusName =~ /^degruyter-/o or
             $corpusName eq 'edp-sciences' or
             $corpusName eq 'emerald' or
             $corpusName eq 'gsl' or
             $corpusName eq 'numerique-premium' or
             $corpusName eq 'oup' ) {
                $structure = "Oui" if $texte =~ m{<body>.+</(sec|p)>.*</body>}o;
                }
        elsif ( $corpusName eq 'ecco' ) {
                $structure = "Oui" if $texte =~ /<p>\s*<wd\b/o;
                }
        elsif ( $corpusName eq 'elsevier' ) {
                $structure = "Oui" if $texte =~ /<body>\s*<ce:sections>\s*<ce:section>/oi;
                }
        elsif ( $corpusName eq 'iop' ) {
                $structure = "Oui" if $texte =~ /<body( .+?)?>\s*<sec-level1\b/o;
                }
        elsif ( $corpusName eq 'nature' ) {
                $structure = "Oui" if $texte =~ m|<bdy>|o;
                $structure = "Non" if $texte =~ m|<bdy/>|o;
                }
        elsif ( $corpusName =~ /^rsc-/o ) {
                $structure = "Oui" if $texte =~ m|<art-body>\s*<section |o;
                }
        elsif ( $corpusName eq 'sage' ) {
                if ( $texte =~ /<body>\s*<full_text\b/o ) {
                        $structure = "Non"
                        }
                elsif ( $texte =~ m{<body>.+</(sec|p)>.*</body>}o ) {
                        $structure = "Oui";
                        }
                }
        elsif ( $corpusName =~ /^springer-/o ) {
                $structure = "Non" if $texte =~ m|<NoBody\b|o;
                }
        elsif ( $corpusName eq 'wiley' ) {
                $structure = "Oui" if $texte =~ /<body( .+?)?>\s*<section\b/oi;
                }
        else    {
                $structure = "Indéterminé";
                }
        }

if ( $xtended eq 'lodex' ) {
        # Variables spécifiques à l'affichage étendu
        my $auteurs      = "";
        my $affiliations = "";
        my $langues      = "";
        my $resume       = "";
        my $motscles     = "";
        my $doi          = "";
        my $pmid         = "";
        if ( $hit{'author'} ) {
                my @authors = @{$hit{'author'}};
                my @names = ();
                my @affiliations = ();
                my %affiliations = ();
                my %lien         = ();
                foreach my $author (@authors) {
                        my %author = %{$author};
                        if ( $author{'name'} ) {
                                push(@names, $author{'name'});
                                }
                        if ( $author{'affiliations'} ) {
                                foreach my $affiliation (@{$author{'affiliations'}}) {
                                        next if not $affiliation;
                                        next if $affiliation =~ /^\s*e-mail\s?:\s/io;
                                        if ( not $affiliations{$affiliation} ) {
                                                push(@affiliations, $affiliation);
                                                $affiliations{$affiliation} = $#affiliations + 1;
                                                }
                                        if ( $author{'name'} ) {
                                                $lien{$#names + 1}{$affiliations{$affiliation}} ++;
                                                }
                                        }
                                }
                        }
                if ( @names ) {
                        if ( $#names > 0 and $xtended eq 'lodex' ) {
                                for ( my $n = 0 ; $n <= $#names ; $n ++ ) {
                                        my $tmp = join(",", sort {$a <=> $b} keys %{$lien{$n + 1}});
                                        if ( $tmp ) {
                                                $names[$n] .= " <sup>$tmp</sup>";
                                                }
                                        }
                                }
                        $auteurs = join(" ; ", @names) if $type ne 'json';
                        $auteurs = \@names if $type eq 'json';
                        }
                if ( @affiliations ) {
                        if ( $type eq 'json' ) {
                                $affiliations = \@affiliations;
                                }
                        else    {
                                # if ( $#names > 0 and $xtended eq 'lodex' ) {
                                #         for ( my $n = 0 ; $n <= $#affiliations ; $n ++ ) {
                                #                $affiliations[$n] = $n + 1 . ") $affiliations[$n]";
                                #                }
                                #        }
                                $affiliations = join(" ; ", @affiliations);
                                }
                        }
                }
        elsif ( $type eq 'json' ) {
                $auteurs = [];
                $affiliations = [];
                }
        if ( $hit{'language'} ) {
                my @langues = @{$hit{'language'}};
                foreach my $item (@langues) {
                        if ( $langue{$item} ) {
                                $item = $langue{$item};
                                }
                        else    {
                                print STDERR "Attention : pas de verbalisation pour le code langue \"$item\"\n";
                                }
                        }
                $langues = join(" ; ", @langues) if $type ne 'json';
                $langues = \@langues if $type eq 'json';
                }
        elsif ( $type eq 'json' ) {
                $langues = [];
                }
        if ( $hit{'abstract'} ) {
                $resume = $hit{'abstract'};
                $resume =~ s/^(abstract|summary)\s*:\s*//io;
                }
        if ( $hit{'doi'} ) {
                $doi = join(" ; ", @{$hit{'doi'}}) if $type ne 'json';
                $doi = \@{$hit{'doi'}} if $type eq 'json';
                }
        elsif ( $type eq 'json' ) {
                $doi = [];
                }
        if ( $hit{'pmid'} ) {
                $pmid = join(" ; ", @{$hit{'pmid'}}) if $type ne 'json';
                $pmid = \@{$hit{'pmid'}} if $type eq 'json';
                }
        elsif ( $type eq 'json' ) {
                $pmid = [];
                }
        if ( $hit{'subject'} ) {
                my @tmp = ();
                foreach my $subject (@{$hit{'subject'}}) {
                        my %subject = %{$subject};
                        if ( $subject{'value'} ) {
                                push(@tmp, $subject{'value'})
                                }
                        }
                my %tmp = ();
                if ( $type eq 'json' ) {
                        my @motscles = grep {not $tmp{$_} ++;} @tmp;
                        $motscles = \@motscles;
                        }
                else    {
                        $motscles = join(" ; ", grep {not $tmp{$_} ++;} @tmp);
                        }
                # Pourquoi cette substitution ?
                # $motscles =~ s| / | ; |go;
                }
        elsif ( $type eq 'json' ) {
                $motscles = [];
                }

        my @valeurs = ($fichier, $titre, $auteurs, $affiliations, $revue, $issn, $eissn, 
                       $isbn, $eisbn, $nom, $dt, $genre, $date, $langues, $resume, $motscles, 
                       $wos, $scienceMetrix, $scopus, $inist, $score, $pdfVersion, $structure, 
                       $id, $ark, $doi, $pmid);
        if ( $type eq 'json' ) {
                json(@valeurs);
                }
        else    {
                my $ligne = join("\t", @valeurs);
                if ( $type eq "csv" ) {
                        print OUT tsv2csv($ligne), "\n";
                        }
                elsif ( $type eq 'tsv' ) {
                        print OUT "$ligne\n";
                        }
                }
        }
else    {
        my @valeurs = ($id, $ark, $fichier, $nom, $score, $pdfVersion, $structure, $date, 
                       $titre, $revue, $issn, $eissn, $dt, $genre, $wos, $scienceMetrix, 
                       $scopus, $inist);
        if ( $type eq 'json' ) {
                json(@valeurs);
                }
        else    {
                my $ligne = join("\t", @valeurs);
                if ( $type eq "csv" ) {
                        print OUT tsv2csv($ligne), "\n";
                        }
                elsif ( $type eq 'tsv' ) {
                        print OUT "$ligne\n";
                        }
                }
        }
}

sub tsv2csv
{
my $ligne = shift;

my @champs = split(/\t/, $ligne);
foreach my $champ (@champs) {
        if ( $champ =~ /[",;]/o ) {
                $champ =~ s/"/""/go;
                $champ = "\"$champ\"";
                }
        }

return join(";", @champs);
}

sub categories
{
my $categories = shift;

my @tmp1 = ();
my @tmp2 = ();

if ( $type eq 'json' ) {
        return \@tmp1 if $#{$categories} < 0;
        foreach my $categorie (@{$categories}) {
                if ( $categorie =~ /^1 - /o and @tmp2 ) {
                        push(@tmp1, [ @tmp2 ]);
                        @tmp2 = ();
                        }
                push(@tmp2, $categorie);
                }
        push(@tmp1, [ @tmp2 ]) if @tmp2;
        return \@tmp1;
        }
else    {
        return join(" ; ", @{$categories});
        }
}

sub json
{
my @valeurs = @_;

$nbDocs --;
my $nb = $#champs;
print OUT "    {\n";
foreach my $champ (@champs) {
        my $valeur = shift @valeurs;
        if ( ref($valeur) eq 'ARRAY' ) {
                my @niv1 = @{$valeur};
                if ( $xtended eq 'lodex' and $simple{$champ} ) {
                        if ( $#niv1 < 0 ) {
                                print OUT "      \"$champ\": null";
                                }
                        else    {
                                my $items = join(" ; ", @niv1);
                                if ( $items =~ /^[-+]? ?\d+(\.\d+)?\z/o ) {
                                        print OUT "      \"$champ\": $items";
                                        }
                                else    {
                                        $items =~ s/\\/\\\\/go;
                                        $items =~ s/"/\\"/go;
                                        print OUT "      \"$champ\": \"$items\"";
                                        }
                                }
                        print OUT "," if $nb --;
                        print OUT "\n";
                        next;
                        }
                if ( $#niv1 < 0 ) {
                        print OUT "      \"$champ\": []", $nb -- ? "," : "", "\n";
                        next;
                        }
                print OUT "      \"$champ\": [\n";
                while (my $niv1 = shift @niv1) {
                        if ( ref($niv1) eq 'ARRAY' ) {
                                my @niv2 = @{$niv1};
                                if ( $champ =~ /^Catégories WoS/o and $xtended eq 'lodex' ) {
                                        foreach my $item (@niv2) {
                                                $item =~ s/\\/\\\\/go;
                                                $item =~ s/"/\\"/go;
                                                }
                                        my $generique = "";
                                        while (my $specifique = shift @niv2) {
                                                if ( $specifique =~ /^1 - /o ) {
                                                        $generique = $specifique;
                                                        next;
                                                        }
                                                elsif ( $generique{$specifique} ) {
                                                        $generique = "1 - $specifique";
                                                        next;
                                                        }
                                                elsif ( $specifique !~ /^\d - /o ) {
                                                        $specifique = "2 - $specifique";
                                                        }
                                                print OUT "        {\n";
                                                print OUT "          \"Nom\": \"$specifique\",\n";
                                                print OUT "          \"Classification\": \[\n";
                                                print OUT "              \"$generique\"\n";
                                                print OUT "            \],\n";
                                                print OUT "          \"Outils\": \[\n";
                                                print OUT "              \"$outil{$champ}\"\n";
                                                print OUT "            \]\n";
                                                print OUT "        }";
                                                print OUT "," if @niv1  or @niv2;
                                                print OUT "\n";
                                                }
                                        next;
                                        }
                                elsif ( $champ =~ /^Catégories /o and $xtended eq 'lodex') {
                                        foreach my $item (@niv2) {
                                                $item =~ s/\\/\\\\/go;
                                                $item =~ s/"/\\"/go;
                                                }
                                        my $specifique = pop @niv2;
                                        print OUT "        {\n";
                                        print OUT "          \"Nom\": \"$specifique\",\n";
                                        print OUT "          \"Classification\": \[\n";
                                        while (my $generique = shift @niv2) {
                                                print OUT "              \"$generique\"", @niv2 ? "," : "", "\n";
                                                }
                                        print OUT "            \],\n";
                                        print OUT "          \"Outils\": \[\n";
                                        print OUT "              \"$outil{$champ}\"\n";
                                        print OUT "            \]\n";
                                        print OUT "        }", @niv1 ? "," : "", "\n";
                                        next;
                                        }
                                if ( $#niv2 < 0 ) {
                                        print OUT "        []", $#niv1 > -1 ? "," : "", "\n";
                                        next;
                                        }
                                print OUT "        [\n";
                                while(my $niv2 = shift @niv2) {
                                        $niv2 =~ s/\\/\\\\/go;
                                        $niv2 =~ s/"/\\"/go;
                                        print OUT "          \"$niv2\"";
                                        print OUT "," if $#niv2 > -1;
                                        print OUT "\n";
                                        }
                                print OUT "        ]";
                                }
                        else    {
                                $niv1 =~ s/\\/\\\\/go;
                                $niv1 =~ s/"/\\"/go;
                                print OUT "        \"$niv1\"";
                                }
                        print OUT "," if $#niv1 > -1;
                        print OUT "\n";
                        }
                print OUT "      ]";
                print OUT "," if $nb;
                print OUT "\n";
                }
        else    {
                if ( $valeur =~ /^[-+]? ?\d+(\.\d+)?\z/o ) {
                        print OUT "      \"$champ\": $valeur";
                        }
                else    {
                        $valeur =~ s/\\/\\\\/go;
                        $valeur =~ s/"/\\"/go;
                        print OUT "      \"$champ\": \"$valeur\"";
                        }
                print OUT "," if $nb;
                print OUT "\n";
                }
        $nb --;
        }
if ( $nbDocs ) {
        print OUT "    },\n";
        }
else    {
        print OUT "    }\n";
        }
}

sub langues
{
return (
        "alg" => "Langues algonquines",
        "amh" => "Amharique",
        "ang" => "Anglo-saxon (env.450-1100)",
        "ara" => "Arabe",
        "arc" => "Araméen d'empire (700-300 av. J.C.)",
        "arm" => "Arménien",
        "cat" => "Catalan",
        "chi" => "Chinois",
        "cze" => "Tchèque",
        "dan" => "Danois",
        "dut" => "Néerlandais",
        "eng" => "Anglais",
        "fre" => "Français",
        "frm" => "Moyen français (1400-1600)",
        "fro" => "Ancien français (842-env.1400)",
        "ger" => "Allemand",
        "gla" => "Gaélique écossais",
        "gle" => "Irlandais",
        "glg" => "Galicien",
        "glv" => "Mannois",
        "gmh" => "Moyen haut-allemand(env. 1050-1500)",
        "grc" => "Grec ancien (jusqu'en 1453)",
        "gre" => "Grec moderne",
        "heb" => "Hébreu",
        "hun" => "Hongrois",
        "ita" => "Italien",
        "lat" => "Latin",
        "lit" => "Lituanien",
        "may" => "Malais",
        "moh" => "Mohawk",
        "mul" => "Multilingue",
        "nai" => "Langues nord-amérindiennes",
        "new" => "Newari",
        "nor" => "Norvégien",
        "pal" => "Pahlavi",
        "peo" => "Vieux perse (env. 600-400 av. J.C.)",
        "per" => "Persan",
        "pol" => "Polonais",
        "por" => "Portugais",
        "roa" => "Langues romanes",
        "rus" => "Russe",
        "san" => "Sanskrit",
        "sco" => "Écossais",
        "spa" => "Espagnol",
        "swe" => "Suédois",
        "syr" => "Syriaque",
        "tur" => "Turc",
        "und" => "Indéterminé",
        "unknown" => "Indéterminé",
        "wel" => "Gallois",
        "zxx" => "Pas de contenu linguistique",
        );
}
