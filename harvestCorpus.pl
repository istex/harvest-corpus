#!/usr/bin/env perl


# Déclaration des pragmas
use strict;
use utf8;
use open qw/:std :utf8/;

# Appel des modules externes de base
use Encode qw(decode_utf8 encode_utf8 is_utf8);
use Getopt::Long;

# Appel des modules spécifiques à l'application
use URI::Encode qw(uri_encode uri_decode);
use LWP::UserAgent;
use HTTP::CookieJar::LWP;
use JSON;
# use Text::Unidecode;

my ($programme) = $0 =~ m|^(?:.*/)?(.+)|;
my  $substitut  = " " x length($programme);
my $usage = "Usage : \n" .
            "    $programme -o 'requête' \n" .
            "    $programme -q 'requête' [ -a | -emt <type de fichier>[,<type de fichier>]* ]\n" .
            "    $substitut [ -d destination ] [ -n [notices.txt]] [ -p préfixe ] [ -s fichier.corpus ] \n" .
            "    $substitut [ -l nombre ] [ -r [nombre]] [ -iv ] [ -j jeton ] [ -z [gzip|bzip2]]\n" . 
            "    $programme -c fichier.corpus ( -a | -emt <type de fichier>[,<type de fichier>]* ) \n" .
            "    $substitut [ -d destination ] [ -n [notices.txt]] [ -p préfixe ] [ -l nombre ] \n" .
            "    $substitut [ -f nombre ] [ -j jeton ] [ -z [gzip|bzip2]]\n" . 
            "    $programme -h \n\n";

my $version     = "4.7.1";
my $dateModif   = "3 Mars 2020";

# Variables
my $aide            = 0;
my $all             = 0;
my $corpus          = "";
my $destination     = ".";
my $from            = 0;
my $gardeId         = 0;
my $istexId         = 0;
my $jeton           = "";
my $limite          = 0;
my $output          = "";
my $quiet           = 0;
my $requete         = "";
my $rien            = 0;
my $source          = "";
my $verbeux         = 0;
my @enrichissements = ();
my @metadonnees     = ();
my @types           = ();
my %echecs          = ();

# Variables indéfinies au départ
my $notices         = undef;
my $prefixe         = undef;
my $random          = undef;
my $zip             = undef;

eval    {
        $SIG{__WARN__} = sub {usage(1);};
        GetOptions(
                "all"               => \$all,
                "corpus=s"          => \$corpus,
                "destination=s"     => \$destination,
                "enrichissements=s" => \@enrichissements,
                "from=i"            => \$from,
                "help"              => \$aide,
                "istexId"           => \$istexId,
                "jeton=s"           => \$jeton,
                "limite=i"          => \$limite,
                "metadonnees=s"     => \@metadonnees,
                "notices:s"         => \$notices,
                "output=s"          => \$output,
                "prefixe=s"         => \$prefixe,
                "query=s"           => \$requete,
                "random:i"          => \$random,
                "source=s"          => \$source,
                "texte=s"           => \@types,
                "verbeux"           => \$verbeux,
                "zip:s"             => \$zip,
                );
        };
$SIG{__WARN__} = sub {warn $_[0];};

if ( $aide ) {
        print "\nProgramme : \n    “$programme”, version $version ($dateModif)\n";
        print "    Permet de décharger un corpus de fichiers textes (PDF, TEI, TXT), de fichiers de \n";
        print "    métadonnées (JSON, Mods, XML) ou de fichiers d’enrichissement depuis la base ISTEX \n";
        print "    à partir d’une requête ou d’un fichier “.corpus”. Permet également de renommer les \n";
        print "    fichiers déchargés et de générer un fichier de notices bibliographiques. \n";
        print "    \n";
        print $usage;
        print "Options : \n";
        print "   -a  télécharge tous les fichiers correspondants aux documents \n";
        print "   -c  utilise le fichier “fichier.corpus” comme source d’identifiants pour télécharger \n";
        print "       les documents (incompatible avec les options “-r” et “-s”) \n";
        print "   -d  indique le répertoire de destination des documents (répertoire courant par défaut)\n";
        print "   -h  affiche cette aide \n";
        print "   -e  liste les enrichissements à télécharger, soit “all” pour l’ensemble, soit \n";
        print "       “abesAuthors”, “abesSubjects”, “multicat”, “nb”, “refBibs”, “teeft” ou “unitex” \n";
        print "   -f  indique à partir de quel numéro de document, on télécharge les fichiers, mais \n";
        print "       seulement avec l’option “-c”. ATTENTION : numérotation informatique qui commence \n";
        print "       à “0”. Pour avoir les fichiers à partir du document n° “50 001”, utiliser la \n";
        print "       valeur “50 000” ! \n";
        print "   -i  utilise l’identifiant ISTEX à la place de l’identifiant ARK dans le fichier \n";
        print "       “fichier.corpus” \n";
        print "   -j  indique le jeton d’authentification obtenu sur “https://api.istex.fr/token/” \n";
        print "   -l  limite le nombre maximum de documents téléchargés au nombre fourni en argument \n";
        print "   -m  liste les fichiers de métadonnées à télécharger, soit “all” pour l’ensemble, \n";
        print "       soit “json”, “mods” ou “xml” \n";
        print "   -n  crée un fichier de notices bibliographiques (sans argument, crée le fichier \n";
        print "       “notices.txt” ou “préfixe.txt” (cf. option “-p”) dans le répertoire courant ou \n";
        print "       celui donné par l’option “-d”) \n";
        print "   -o  indique la requête à tester, entre simples quotes en présence de blancs ou de \n";
        print "       caractères spéciaux, et simplement retourne le nombre de documents attendus ou \n";
        print "       un message d'erreur \n";
        print "   -p  indique le préfixe utilisé pour renommer les fichiers téléchargés (par défaut, “f”).\n";
        print "       Ce préfixe doit commencer par une lettre suivie de caractères alphanumériques ou \n";
        print "       de tirets bas (“_”). Les traits d’union sont autorisés au milieu du préfixe. \n";
        print "       Celui-ci est ensuite suivi d'un numéro séquentiel et de l'extension correspondant \n";
        print "       au type de document téléchargé. Si la valeur de l’option “-p” est “0”, alors \n";
        print "       le fichier garde son nom original, c’est-à-dire l’identifiant ISTEX \n";
        print "   -q  indique la requête à utiliser, entre simples quotes en présence de blancs ou de \n";
        print "       caractères spéciaux (incompatible avec l’option “-c”)\n";
        print "   -r  provoque une sortie dans un ordre aléatoire en fonction d'une “graine” aléatoire \n";
        print "       si l'argument est absent ou égal à 0, ou en fonction du nombre entier positif non nul \n";
        print "       fourni en argument (incompatible avec l’option “-c” et limité à 10.000 documents)\n";
        print "   -s  indique le nom du fichier “.corpus” généré. Par défaut, génère le fichier \n";
        print "       “id.corpus” ou “préfixe.corpus” (cf. option “-p”) dans le répertoire courant \n";
        print "       ou celui donné par l’option “-d” (incompatible avec l’option “-c”)\n";
        print "   -t  liste les fichiers de texte intégral à télécharger, soit “all” pour l’ensemble, \n";
        print "       soit “ocr”, “pdf”, “tei”, “txt” ou “zip”\n";
        print "   -v  garde les métadonnées ISTEX au format JSON dans un fichier “logRequete.txt” dans \n";
        print "       le répertoire courant ou celui donné par l’option “-d”\n";
        print "   -z  indique le nom du programme à utiliser pour compresser les fichiers générés, \n";
        print "       à savoir “logRequete.txt”, “id.corpus”, “notices.txt” ou équivalents. Par \n";
        print "       défaut, utilise “gzip” \n\n";
        print "Exemples : \n";
        print "   $programme -q '(host.title:\"Biofutur\" OR host.issn:\"0294-3506\")' -t pdf,tei \n";
        print "   $substitut -d FichiersPDF -s Biofutur.corpus -p biofutur -v\n";
        print "   $programme -c Biofutur.corpus -m mods -d Metadata\n\n";
        exit 0;
        }

usage(2) if not $requete and not $output and not $corpus;

# Gestion des interruptions
$SIG{'HUP'} = 'nettoye';
$SIG{'INT'} = 'nettoye';
$SIG{'QUIT'} = 'nettoye';
$SIG{'TERM'} = 'nettoye';

# Paramètres de l'API ISTEX
my $base  = "https://api.istex.fr";
my $url   = "$base/document/?q=";
my $out   = "output=*";
my $size  = 250;
my $echec = 0;

# Initialisation de l'agent
my $agent = LWP::UserAgent->new(
                        cookie_jar => HTTP::CookieJar::LWP->new,
                        );
$agent->agent("$programme/$version");
$agent->default_header("Accept"          => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
$agent->default_header("Accept-Language" => "fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3");
$agent->default_header("Accept-Encoding" => "gzip, deflate");
$agent->default_header("Connection"      => "keep-alive");
if ( $jeton ) {
        $agent->default_header("Authorization"      => "Bearer $jeton");
        }
# Allongement du temps d'attente
$agent->timeout(300);
$agent->env_proxy;

if ( $output ) {
        $output = decode_utf8($output);
        # Cas de l'interrogation simple
        my $uri = "$url" . propre($output) . "&size=0";
        my ($code, $json) = mon_get("$uri");
        my $perl = undef;
        if ( defined $json ) {
                $perl = decode_json $json;
                my %top = %{$perl};
                my $total = $top{'total'};
                if ( defined $top{'erreur'} ) {
                        my $message = $top{'erreur'};
                        print STDERR "$message\n";
                        exit(17);
                        }
                else    {
                        print "$total\n";
                        exit(0);
                        }
                }
        }

if ( $requete ) {
        $requete = decode_utf8($requete);
        }

# Vérification des options choisies
if ( $all ) {
        @enrichissements = ('all');
        @metadonnees     = ('all');
        @types           = ('all');
        }
else    {
        @enrichissements = map {lc($_)} split(/,/, join(",", @enrichissements));
        usage(4) if grep(!/^(all|abesAuthors|abesSubjects|multicat|nb|refBibs|teeft|unitex)\z/i, @enrichissements);
        @metadonnees = map {lc($_)} split(/,/, join(",", @metadonnees));
        usage(4) if grep(!/^(all|json|mods|xml)\z/i, @metadonnees);
        @types = map {lc($_)} split(/,/, join(",", @types));
        usage(4) if grep(!/^(all|ocr|pdf|tei|txt|zip)\z/i, @types);
        }

if ( not $all and 
     not @enrichissements and 
     not @metadonnees and 
     not @types ) {
        $rien = 1;
        }

usage(5) if $corpus and ($requete or $source);
if ( $limite and $limite < 1 ) {
        print STDERR "Erreur : le nombre limite de documents (option “-l”) doit être un entier positif non nul !\n";
        usage(6);
        }
if ( $random and $random < 0 ) {
        print STDERR "Erreur : la “graine” aléatoire (option “-r”) doit être un entier positif !\n";
        usage(7);
        }

if ( defined $prefixe ) {
        if ( not $prefixe ) {
                $gardeId ++;
                }
        elsif ( $prefixe !~ /^[A-Za-z](\w*-)?\w+\z/ ) {
                print STDERR "Erreur : préfixe non-conforme\n";
                exit 3;
                }
        }
elsif ( $requete ) {
        $prefixe = "f";
        }

if ( not $source ) {
        if ( $prefixe and $prefixe ne 'f' ) {
                $source = "$destination/$prefixe.corpus";
                $source =~ s/_\.corpus\z/.corpus/;
                }
        else    {
                $source = "$destination/id.corpus";
                }
        }

if ( defined $notices and not $notices ) {
        if ( $prefixe and $prefixe ne 'f' ) {
                $notices = "$destination/$prefixe.txt";
                $notices =~ s/_\.txt\z/.txt/;
                }
        else    {
                $notices = "$destination/notices.txt";
                }
        }

if ( defined $zip ) {
        if ( not $zip ) {
                $zip = "gzip";
                }
        elsif ( $zip =~ /^(gzip|bzip2)\z/i ) {
                $zip = lc($zip);
                }
        else    {
                print STDERR "Erreur : \"$zip\" n’est pas une valeur acceptable pour l’option “-z” !\n";
                usage(8);
                }
        }
my %extension = (
        "bzip2" => "bz2",
        "gzip"  => "gz",
        );

if ( $verbeux ) {
        if ( $zip ) {
                open(LOG, "| $zip -c -9 > $destination/logRequete.txt.$extension{$zip}") or die "$!,";
                binmode(LOG, ":utf8");
                }
        else    {
                open(LOG, ">:raw", "$destination/logRequete.txt") or die "$!,";
                }
        }
else    {
        open(LOG, "> /dev/null") or die "$!,";
        }

my $tmpfile = "$destination/tmp$$.txt";

# Variables concernant les documents
my $num     = 0;
my $format  = "";
my $referer = undef;        # Est-ce utile ?
my $suivant = "";
my $total   = undef;
my @ark     = ();
my @id      = ();
my %nom     = ();
my %notice  = ();

# Liste des langues (codes ISO 639)
my %langue = initialise();

# Correspondance entre noms de corpus et éditeurs
my %pretty = (
        "acs"                 => "American Chemical Society",
        "bmj"                 => "BMJ",
        "brepols-ebooks"      => "Brepols [e-books]",
        "brepols-journals"    => "Brepols [journals]",
        "brill-hacco"         => "Brill HACCO",
        "brill-journals"      => "Brill [journals]",
        "cambridge"           => "Cambridge",
        "degruyter-journals"  => "Degruyter [journals]",
        "duke"                => "Duke",
        "ecco"                => "ECCO",
        "edp-sciences"        => "EDP Sciences",
        "eebo"                => "EEBO",
        "elsevier"            => "Elsevier",
        "emerald"             => "Emerald",
        "gsl"                 => "GSL",
        "iop"                 => "IOP",
        "lavoisier"           => "Lavoisier",
        "nature"              => "Nature",
        "numerique-premium"   => "Numérique Premium",
        "open-edition"        => "Open Edition",
        "oup"                 => "OUP",
        "rsc-ebooks"          => "RSC [e-books]",
        "rsc-journals"        => "RSC [journals]",
        "rsl"                 => "Royal Society of London",
        "sage"                => "Sage",
        "springer-ebooks"     => "Springer [e-books]",
        "springer-journals"   => "Springer [journals]",
        "taylor-francis"      => "Taylor & Francis",
        "wiley"               => "Wiley",
        );

# Ouverture du fichier de notices bibliographiques
if ( $notices ) {
        if ( $zip ) {
                open(OUT, "| $zip -c -9 > $notices.$extension{$zip}") or die "$!,";
                binmode(OUT, ":utf8");
                }
        else    {
                open(OUT, ">:utf8", $notices) or die "$!,";
                }
        }

if ( $requete ) {
        # Ouverture en écriture du fichier “.corpus”
        if ( $source ) {
                my $date = date();
                if ( $zip ) {
                        open(SRC, "| $zip -c -9 > $source.$extension{$zip}") or die "$!,";
                        binmode(SRC, ":utf8");
                        }
                else    {
                        open(SRC, ">:utf8", $source) or die "$!,";
                        }
                print SRC "#\n# Fichier .corpus\n#\n";
                print SRC "title        : <à compléter> \n";
                print SRC "author       : ";
                if ( $ENV{'USER'} ) {
                        print SRC uc($ENV{'USER'});
                        }
                print SRC "\npublisher    : <à compléter> \n";
                print SRC "query        : ", decoupe2($requete);
                print SRC "date         : $date\n";
                print SRC "license      : CC-By ?\n";
                print SRC "versionInfo  : 1.0 ?\n";
                }

        # Ouverture du fichier temporaire
        open(TMP, ">:utf8", $tmpfile) or die "Impossible d'ouvrir le fichier temporaire \"$tmpfile\" : $!,";

        # Première itération
        my $uri = "$url" . propre($requete) . "&$out&size=$size";
        if ( defined $random ) {
                if ( $limite > 10000 or $limite == 0 ) {
                        $limite = 10000;
                        }
                $uri .= "&rankBy=random";
                if ( $random ) {
                        $uri .= "&randomSeed=$random";
                        }
                }
        else    {
                $uri .= "&scroll=267s";
                }
        $uri .= "&sid=scodex-harvest-corpus";
        my ($code, $json) = mon_get("$uri");
        my $perl = undef;
        if ( defined $json ) {
                if ( $verbeux ) {
                        foreach my $ligne (split(/[\n\r]+/, $json)) {
                                next if $ligne =~ /"(scrollId|nextScrollURI)": /o;
                                print LOG "$ligne\n";
                                }
                        }
                print OUT "#\n# Requête : \"$requete\"\n#\n" if $notices;
                $perl = decode_json $json;
                my %top = %{$perl};
                $total = $top{'total'};
                if ( $total > 0 ) {
                        if ( defined $random ) {
                                ($random) = $top{'firstPageURI'} =~ /\brandomSeed=(\d+)/;
                                print SRC "randomSeed   : $random\n";
                                }
                        if ( $limite and $limite < $total ) {
                                print SRC "total        : $limite / $total documents\n\n";
                                print OUT "# Nombre de réponses : $limite / $total\n#\n\n" if $notices;
                                }
                        else    {
                                print SRC "total        : $total document", $total > 1 ? "s" : "", "\n\n";
                                print OUT "# Nombre de réponses : $total\n#\n\n" if $notices;
                                }
                        print SRC "[ISTEX]\n";
                        if ( $limite and $limite < $total ) {
                                $total = $limite;
                                }
                        $format = sprintf("%%0%dd", length($total) + 1);
                        if ( $top{'scrollId'} ) {
                                my $scrollId = $top{'scrollId'};
                                if ( $top{'nextScrollURI'} ) {
                                        $suivant = "$url" . "1&$out&size=$size&scroll=167s&";
                                        $suivant .= "scrollId=$scrollId&sid=scodex-harvest-corpus";;
                                        }
                                else    {
                                        $suivant = "";
                                        }
                                }
                        elsif ( $top{'firstPageURI'} ) {
                                if ( $top{'nextPageURI'} ) {
                                        $suivant = $top{'nextPageURI'} . "&sid=scodex-harvest-corpus";
                                        }
                                else    {
                                        $suivant = "";
                                        }
                                }
                        else    {
                                print STDERR "Pas de \"scrollId\"\n";
                                exit 10;
                                }
                        my @hits = @{$top{'hits'}};
                        foreach my $hit (@hits) {
                                traite($hit);
                                if ( $limite and $num >= $limite ) {
                                        $suivant = "";
                                        last;
                                        }
                                }
                        }
                else    {
                        print OUT "# Nombre de réponses : 0\n#\n\n" if $notices;
                        print STDERR "Aucun document pour la requête \"$requete\"\n";
                        exit 11;
                        }
                }
        else    {
                print STDERR "Aucune réponse du serveur \"$base\"\n";
                exit 12;
                }

        # Itérations suivantes
        while ( $suivant ) {
                ($code, $json) = mon_get("$suivant");
                $perl = undef;
                if ( defined $json ) {
                        if ( $verbeux ) {
                                foreach my $ligne (split(/[\n\r]+/, $json)) {
                                        next if $ligne =~ /"(scrollId|nextScrollURI)": /o;
                                        print LOG "$ligne\n";
                                        }
                                }
                        $perl = decode_json $json;
                        my %top = %{$perl};
                        if ( $top{'firstPageURI'} ) {
                                if ( $top{'nextPageURI'} ) {
                                        $suivant = $top{'nextPageURI'} . "&sid=scodex-harvest-corpus";
                                        }
                                else    {
                                        $suivant = "";
                                        }
                                }
                        elsif ( not $top{'nextScrollURI'} ) {
                                $suivant = "";
                                }
                        my @hits = @{$top{'hits'}};
                        foreach my $hit (@hits) {
                                traite($hit);
                                if ( $limite and $num >= $limite ) {
                                        $suivant = "";
                                        last;
                                        }
                                }
                        }
                else    {
                        print STDERR "Aucune réponse du serveur \"$base\"\n";
                        exit 13;
                        }
                }

        # Test du nombre de documents
        if ( $num < $total ) {
                print STDERR "Attention : $num ", $num > 1 ? "documents reçus" : "document reçu";
                print STDERR " pour $total documents attendus !\n";
                }

        # Récupération des fichiers sélectionnés
        close TMP;
        open(TMP, "<:utf8", $tmpfile) or die "Impossible d'ouvrir le fichier temporaire \"$tmpfile\" : $!,";
        while (my $ligne = <TMP>) {
                chomp($ligne);
                $code = dl(split(/\t/, $ligne));
                }
        close TMP;

        # Tentative de récupération des rejets
        if ( %echecs ) {
                $quiet ++;
                my $old = keys %echecs;
                my $nb = 2;
                while ( $nb ) {
                        $nb --;
                        foreach my $item (map  {$_->[0]}
                                        sort {$a->[1] <=> $b->[1]}
                                        map  {[$_, /(\d+)\t/]} keys %echecs) {
                                delete $echecs{$item};
                                $code = dl(split(/\t/, $item));
                                }
                        my $new = keys %echecs;
                        if ( $new < $old ) {
                                $old = $new;
                                $nb ++;
                                }
                        else    {
                                sleep 10;
                                }
                        }
                }

        if ( %echecs ) {
                print STDERR "Échec pour : \n";
                foreach my $item (map  {$_->[0]}
                                sort {$a->[1] <=> $b->[1]}
                                map  {[$_, /(\d+)\t/]} keys %echecs) {
                        print STDERR "$item\n";
                        }
                }

        close SRC if $source;
        close OUT if $notices;
        close LOG;

        nettoye(0);
        }

elsif ( $corpus ) {
        if ( $rien ) {
                print STDERR "Attention : vous devez indiquer au moins un type de fichier !\n\n";
                usage(18);
                }

        my $ark   = "";
        my $id    = "";
        my $istex = "";
        my $nom   = "";
        my $num   = 0;
        my $sep   = "";
        my $suite = 0;
        my $type  = "";

        $limite += $from;
        if ( not -f $corpus ) {
                print STDERR "Erreur : fichier \"$corpus\" absent\n";
                exit 14;
                }
        elsif ( $corpus =~ /\.g?[zZ]\z/ ) {
                open(INP, "gzip -cd $corpus |") or 
                        die "Erreur : Impossible d'ouvrir \"$corpus\" : $!,";
                binmode(INP, ":utf8");
                }
        elsif ( $corpus =~ /\.bz2\z/ ) {
                open(INP, "bzip2 -cd $corpus |") or 
                        die "Erreur : Impossible d'ouvrir \"$corpus\" : $!,";
                binmode(INP, ":utf8");
                }
        else    {
                open(INP, "<:utf8", $corpus) or 
                        die "Erreur : Impossible d'ouvrir \"$corpus\" : $!,";
                }
        while(<INP>) {
                chomp;
                s/\r//go;
                if ( m|^total +: (\d+)( / \d+)? documents?|o ) {
                        $total = $1;
                        }
                elsif ( /^query +: (.+)/o ) {
                        $requete = $1;
                        $suite ++;
                        }
                elsif ( $suite and /^  +(.+)/o ) {
                        $requete .= " " . $1;
                        $suite ++;
                        }
                elsif ( $suite and ( /^\w+ /o or /^\*$/o ) ) {
                        $suite = 0;
                        }
                elsif ( /^\[ISTEX\]\s*/o ) {
                        $suite = 0;
                        $istex = 1;
                        if ( not defined $total ) {
                                $total = total($corpus);
                                }
                        $format = sprintf("%%0%dd", length($total) + 1);
                        }
                elsif (/^\[.+?\]\s*/o) {
                        $suite = 0;
                        $istex = 0;
                        }
                elsif ($istex and /^ark +/o) {
                        $num ++;
                        next if $num <= $from;
                        ($type, $ark, $sep, $nom) = split(/\s+/);
                        $ark = "ark:$ark" if $ark !~ /^ark:/o;
                        if ( $prefixe ) {
                                $nom{$ark} = $prefixe . sprintf($format, $num);
                                }
                        elsif ( $nom ) {
                                $nom{$ark} = $nom;
                                }
                        else    {
                                $nom{$ark} = 'f' . sprintf($format, $num);
                                }
                        push(@ark, $ark);
                        }
                elsif ($istex and /^id +/o) {
                        $num ++;
                        next if $num <= $from;
                        ($type, $id, $sep, $nom) = split(/\s+/);
                        if ( $prefixe ) {
                                $nom{$id} = $prefixe . sprintf($format, $num);
                                }
                        elsif ( $nom ) {
                                $nom{$id} = $nom;
                                }
                        else    {
                                $nom{$id} = 'f' . sprintf($format, $num);
                                }
                        push(@id, $id);
                        }
                if ( $istex and $num > 0 and $num % 100 == 0 ) {
                        recherche();
                        }
                last if $limite and $num >= $limite;
                }
        close INP;

        recherche();
        }


exit 0;


sub usage
{
my $code = shift;

print STDERR $usage;

exit $code;
}

sub date
{
my @time = localtime();

my $jour = (qw(Dimanche Lundi Mardi Mercredi Jeudi Vendredi Samedi))[$time[6]];
my $mois = (qw(Janvier Février Mars Avril Mai juin Juillet Août Septembre Octobre Novembre Décembre))[$time[4]];
my $annee = $time[5] + 1900;

my $date = "$jour $time[3] $mois $annee ";
$date .= sprintf("%02d:%02d:%02D", $time[2], $time[1], $time[0]);

return $date;
}

sub mon_get
{
my $cible = shift;
my $destination = shift;

my $requete = HTTP::Request->new(GET => "$cible");

my $reponse = $agent->request($requete, $destination);
my $code = $reponse->code;

# Vérification de la réponse
if ( $destination ) {
        if ( defined $reponse->header('Client-Aborted') ) {
                die "Client-Aborted : $reponse->header('Client-Aborted'),";
                }
        elsif ( defined $reponse->header('X-Died') ) {
                die "X-Died : $reponse->header('X-Died'),";
                }
        }
if ($reponse->is_success) {
        $referer = $reponse->header('location');
        $echec = 0;
        if ( $destination ) {
                return $code;
                }
        else    {
                return ($code, $reponse->decoded_content);
                }
        }
else    {
        my $message = $reponse->status_line;
        if ( $output ) {
                $message =~ s/"/\\"/go;
                return ($code, "{\"total\": 0, \"erreur\": \"$message\"}");
                }
        elsif ( $message =~ /\b(read timeout|Proxy Error)\b/o and $echec < 10 ) {
                $echec ++;
                print STDERR "Interruption n° $echec : \"$message\", ", date(), "\n";
                print STDERR "             pour \"$cible\"\n" if $echec == 1;
                sleep 60;
                return mon_get($cible, $destination);
                }
        else    {
                $cible =~ s/(scrollId=\w).+?(\w&)/$1...$2/;
                print STDERR "Erreur : $message pour URL \"$cible\"\n";
                nettoye(15);
                }
        }


}

sub traite
{
my $hit = shift;

$num ++;
my %hit = %{$hit};
my $succes = 0;
my $extension = "";

if ( $source ) {
        my $racine = "";
        if ( $gardeId ) {
                $racine = $hit{'id'};
                }
        else    {
                $racine = $prefixe . sprintf($format, $num);
                }
        if ( $istexId ) {
                print SRC "id  $hit{'id'}    # $racine\n";
                }
        elsif ( $hit{'arkIstex'} ) {
                print SRC "ark $hit{'arkIstex'}                  # $racine\n";
                }
        else    {
                print SRC "id  $hit{'id'}    # $racine\n";
                }
        }

if ( $notices ) {
        my @notice = notice($hit, $num, $total);
        if ( @notice ) {
                foreach my $ligne (@notice) {
                        print OUT "$ligne\n";
                        }
                print OUT "   \n";
                }
        }

return if $rien;

if ( @types and defined $hit{'fulltext'} ) {
        my @fulltext = @{$hit{'fulltext'}};
        foreach my $fulltext (@fulltext) {
                my %fulltext = %{$fulltext};
                if ( grep(/^all\z/, @types) ) {
                        print TMP join("\t", ($num, "", $hit{'id'}, $fulltext{'uri'}, 
                                              $fulltext{'extension'}, $fulltext{'mimetype'})) . "\n";
                        $succes ++;
                        next;
                        }
                foreach my $type (@types) {
                        if ( $fulltext{'mimetype'} =~ /\b$type\b/ or
                                $fulltext{'extension'} =~ /\b$type\b/ ) {
                                print TMP join("\t", ($num, "", $hit{'id'}, $fulltext{'uri'}, 
                                                      $fulltext{'extension'}, $fulltext{'mimetype'})) . "\n";
                                $succes ++;
                                last;
                                }
                        }
                }
        }

if ( @metadonnees and defined $hit{'metadata'} ) {
        my @metadata = @{$hit{'metadata'}};
        foreach my $metadata (@metadata) {
                my %metadata = %{$metadata};
                if ( grep(/^all\z/, @metadonnees ) ) {
                        print TMP join("\t", ($num, "", $hit{'id'}, $metadata{'uri'}, 
                                              $metadata{'extension'}, $metadata{'mimetype'})) . "\n";
                        $succes ++;
                        next;
                        }
                foreach my $metadonnee (@metadonnees) {
                        if ( $metadata{'extension'} =~ /\b$metadonnee\b/ ) {
                                print TMP join("\t", ($num, "", $hit{'id'}, $metadata{'uri'}, 
                                                      $metadata{'extension'}, $metadata{'mimetype'})) . "\n";
                                $succes ++;
                                last;
                                }
                        }
                }
        }

if ( @enrichissements and defined $hit{'enrichments'} ) {
        my %enrichments = %{$hit{'enrichments'}};
        foreach my $enrichment (sort keys %enrichments) {
                next if $#{$enrichments{$enrichment}} < 0;
                my %enrichment = %{$enrichments{$enrichment}->[0]};
                if ( grep(/^all\z/, @enrichissements ) ) {
                        print TMP join("\t", ($num, "", $hit{'id'}, $enrichment{'uri'}, 
                                             "$enrichment.$enrichment{'extension'}", $enrichment{'mimetype'})) . "\n";
                        $succes ++;
                        next;
                        }
                foreach my $enrichissement (@enrichissements) {
                        if ( $enrichissement =~ /^$enrichment\z/i ) {
                                print TMP join("\t", ($num, "", $hit{'id'}, $enrichment{'uri'}, 
                                                     "$enrichment.$enrichment{'extension'}", $enrichment{'mimetype'})) . "\n";
                                $succes ++;
                                last;
                                }
                        }
                }
        }

if ( not $succes ) {
        my $types = join("/", sort @types);
        print STDERR "Pas de lien pour le document ", uc($types) . " \"$hit{'id'}\"\n";
        }

return;
}

sub recherche
{
if ( $notices ) {
        if ( $requete ) {
                print OUT "#\n# Requête : \"$requete\"\n#\n";
                }
        else    {
                print OUT "#\n# Requête inconnue !\n#\n";
                }
        if ( $limite and $limite < $total ) {
                print OUT "# Nombre de réponses : $limite / $total\n#\n\n";
                }
        else    {
                print OUT "# Nombre de réponses : $total\n#\n\n";
                }
        }

$requete = "";

if ( @ark ) {
        $requete = join(" ", map {'"' . $_ . '"';} @ark);
        }
@ark = ();

if ( @id ) {
        $requete .= " OR " if $requete;
        $requete .= "id:(" . join(" ", @id) . ")";
        }
@id = ();

return if not $requete;

$requete =~ s/ +/+/go;

my $uri = "$url$requete&$out&size=$size&scroll=267s&sid=scodex-harvest-corpus";
while($uri) {
        my ($code, $json) = mon_get("$uri");
        my $perl = undef;
        if ( defined $json ) {
                $perl = decode_json $json;
                my %top = %{$perl};
                $total = $top{'total'};
                if ( $total > 0 ) {
                        $format = sprintf("%%0%dd", length($total) + 1) if not $format;
                        if ( $top{'scrollId'} ) {
                                my $scrollId = $top{'scrollId'};
                                if ( $top{'nextScrollURI'} ) {
                                        $uri = "$url" . "1&$out&size=$size&scroll=167s&";
                                        $uri .= "scrollId=$scrollId&sid=scodex-harvest-corpus";;
                                        }
                                else    {
                                        $uri = "";
                                        }
                                }
                        else    {
                                print STDERR "Pas de \"scrollId\"\n";
                                exit 16;
                                }
                        my @hits = @{$top{'hits'}};
                        foreach my $hit (@hits) {
                                traite2($hit);
                                }
                        }
                }
        }

if ( $notices ) {
        foreach my $valeur (sort {$a <=> $b} keys %notice) {
                foreach my $ligne (@{$notice{$valeur}}) {
                        print OUT "$ligne\n";
                        }
                print OUT "   \n";
                }
        %notice = ();
        }
}

sub traite2
{
my $hit = shift;

my %hit = %{$hit};
my $succes = 0;
my $extension = "";

my $ark = "";
if ( defined $hit{'arkIstex'} ) {
        $ark = $hit{'arkIstex'};
        }
my $id  = $hit{'id'};

my $nom = undef;
if ( $gardeId ) {
        $nom = $id;
        }
elsif ( defined $nom{$ark} ) {
        $nom = $nom{$ark};
        delete $nom{$ark};
        }
elsif ( defined $nom{$id} ) {
        $nom = $nom{$id};
        delete $nom{$id};
        }
else    {
        if ( $ark ) {
                print STDERR "Pas de nom de fichier pour le document ark:\"$ark\"\n";
                }
        else    {
                print STDERR "Pas de nom de fichier pour le document id:\"$id\"\n";
                }
        return;
        }

if ( $notices ) {
        my ($position) = $nom =~ /(?:0*)(\d+)\z/o;
        push(@{$notice{$position}}, notice($hit, $position, $total));
        }

if ( @types and defined $hit{'fulltext'} ) {
        my @fulltext = @{$hit{'fulltext'}};
        foreach my $fulltext (@fulltext) {
                my %fulltext = %{$fulltext};
                if ( grep(/^all\z/, @types) ) {
                        dl(0, $nom, $id, $fulltext{'uri'}, $fulltext{'extension'}, $fulltext{'mimetype'});
                        $succes ++;
                        next;
                        }
                foreach my $type (@types) {
                        if ( $fulltext{'mimetype'} =~ /\b$type\b/ or
                                $fulltext{'extension'} =~ /\b$type\b/ ) {
                                dl(0, $nom, $id, $fulltext{'uri'}, $fulltext{'extension'}, $fulltext{'mimetype'});
                                $succes ++;
                                last;
                                }
                        }
                }
        }

if ( @metadonnees and defined $hit{'metadata'} ) {
        my @metadata = @{$hit{'metadata'}};
        foreach my $metadata (@metadata) {
                my %metadata = %{$metadata};
                if ( grep(/^all\z/, @metadonnees ) ) {
                        dl(0, $nom, $id, $metadata{'uri'}, $metadata{'extension'}, $metadata{'mimetype'});
                        $succes ++;
                        next;
                        }
                foreach my $metadonnee (@metadonnees) {
                        if ( $metadata{'extension'} =~ /\b$metadonnee\b/ ) {
                                dl(0, $nom, $id, $metadata{'uri'}, $metadata{'extension'}, $metadata{'mimetype'});
                                $succes ++;
                                last;
                                }
                        }
                }
        }

if ( @enrichissements and defined $hit{'enrichments'} ) {
        my %enrichments = %{$hit{'enrichments'}};
        foreach my $enrichment (sort keys %enrichments) {
                next if $#{$enrichments{$enrichment}} < 0;
                my %enrichment = %{$enrichments{$enrichment}->[0]};
                if ( grep(/^all\z/, @enrichissements ) ) {
                        dl(0, $nom, $id, $enrichment{'uri'}, "$enrichment.$enrichment{'extension'}", $enrichment{'mimetype'});
                        $succes ++;
                        next;
                        }
                foreach my $enrichissement (@enrichissements) {
                        if ( $enrichissement =~ /^$enrichment\z/i ) {
                                dl(0, $nom, $id, $enrichment{'uri'}, "$enrichment.$enrichment{'extension'}", $enrichment{'mimetype'});
                                $succes ++;
                                last;
                                }
                        }
                }
        }

if ( not $succes ) {
        my $types = join("/", sort @types);
        print STDERR "Pas de lien pour le document ", uc($types) . " \"$hit{'id'}\"\n";
        }

return;
}

sub dl
{
my ($rang, $nom, $id, $lien, $ext, $mt) = @_;
my $item = join("\t", @_);

my $extension = "";
if ( $ext =~ /\w+\.\w+/o ) {
        $extension = "_$ext";
        }
else    {
        $extension = ".$ext";
        }
# $mt =~ s|^application/\w+\+xml\z|application/xml|o;

my $fichier = "";
if ( $nom ) {
        $fichier = "$nom$extension";
        }
elsif ( $gardeId ) {
        $fichier = "$id$extension";
        }
elsif ( $rang ) {
        $fichier = "$prefixe" . sprintf($format, $rang) . "$extension";
        }
else    {
        print STDERR "Erreur de chargement pour le document id:\"$id\"\n";
        return;
        }

my $code = mon_get($lien."?sid=scodex-harvest-corpus", "$destination/$fichier");
if ( $code != 200 ) {
        print STDERR "Erreur de chargement pour le document ", uc($ext) . " \"$id\" : code $code\n" if not $quiet;
        $echecs{$item} ++;
        if ( -f "$destination/$fichier" ) {
                unlink "$destination/$fichier";
                }
        return $code;
        }

# Vérification du fichier reçu
open(FILE, "file --brief --mime-type $destination/$fichier |") or die "$!,";
chomp(my $type = <FILE>);
close FILE;

if ( $type ne $mt ) {
        if ( $type eq "text/html" ) {
                if ( $ext eq 'unitex.tei' ) {
                        my $ok = 0;
                        open(TEI, "<:utf8", "$destination/$fichier") or die "Impossible d’ouvrir le fichier \"$destination/$fichier\" : $!,";
                        while(<TEI>) {
                                if ( /<TEI\b/o ) {
                                        $ok ++;
                                        last;
                                        }
                                elsif ( /<HTML\b/io ) {
                                        $ok = 0;
                                        last;
                                        }
                                }
                        close TEI;
                        return $code if $ok;
                        }
                $echecs{$item} ++;
                unlink "$destination/$fichier";
                print STDERR "Authentification demandée pour le document ", uc($ext) . " \"$id\" [$fichier]\n" if not $quiet;
                return 0;
                }
#         else    {
#                 print STDERR "Différence de type pour le document ", uc($ext) . " \"$id\" [$fichier] : $type ≠ $mt\n" if not $quiet;
#                 }
        }

return $code;
}

sub initialise
{
my %hash =  ();

while (<DATA>) {
        next if /^\s*#/o;
        next if /^\s*\z/o;
        if ( /^% +(\w+)/o ) {
                my $token = $1;
                last if $token eq "FIN";
                }
        elsif ( /\t/o ) {
                chomp;
                s/\r//o;
                my ($code, $intitule) = split(/\t/);
                $hash{$code} = $intitule;
                $hash{lc($code)} = $intitule;
                }
        }

return %hash;
}

sub propre
{
my $chaine = shift;

# Vérification de jeu de caractères (doit être UTF-8)
if ( is_utf8($chaine, Encode::FB_QUIET) ) {

##        # Échappement des caractères réservés
##        $chaine =~ s#([-+&|!(){}^"~*?:\/])#\\$1#go;
##        $chaine =~ s#([][])#\\$1#go;

        # URLencodage
        $chaine = uri_encode($chaine);
        $chaine =~ s/&/%26/go;

        return $chaine;
        }
else    {
        return undef;
        }
}

sub notice
{
my ($top, $nb, $max) = @_;
my @lignes = ();
my $ligne = "";

my %top = %{$top};

# Numéro/total
push(@lignes, "$nb/$max");

# Champ NO
if ( defined $top{'arkIstex'} ) {
        $ligne = "NO : ISTEX $top{'arkIstex'}";
        }
else    {
        $ligne = "NO : ISTEX $top{'id'}";
        }
if ( $top{'corpusName'} ) {
        my $corpusName = $top{'corpusName'};
        if ( $pretty{$corpusName} ) {
                $ligne .= " (corpus $pretty{$corpusName})";
                }
        else    {
                $ligne .= " (corpus \u$top{'corpusName'})";
                }
        }
push(@lignes, $ligne);

# Champ TI
if ( $top{'title'} ) {
        $ligne = "TI : $top{'title'}";
        push(@lignes, $ligne);
        }

# Champ AU + AF
if ( $top{'author'} ) {
        my @authors = @{$top{'author'}};
        my @names = ();
        my @affiliations = ();
        my %affiliations = ();
        foreach my $author (@authors) {
                my %author = %{$author};
                if ( $author{'name'} ) {
                        push(@names, $author{'name'});
                        }
                if ( $author{'affiliations'} ) {
                        foreach my $affiliation (@{$author{'affiliations'}}) {
                                next if $affiliation =~ /^\s*e-mail\s?:\s/io;
                                if ( not $affiliations{$affiliation} ) {
                                        push(@affiliations, $affiliation);
                                        }
                                if ( $author{'name'} ) {
                                        push(@{$affiliations{$affiliation}}, sprintf("%d aut.", $#names + 1));
                                        }
                                else    {
                                        push(@{$affiliations{$affiliation}}, "");
                                        }
                                }
                        }
                }
        if ( @names ) {
                $ligne = "AU : " . join(" ; ", @names);
                push(@lignes, $ligne);
                }
        if ( @affiliations ) {
                foreach my $affiliation (@affiliations) {
                        my @tmp = grep(/./, @{$affiliations{$affiliation}});
                        if ( @tmp ) {
                                $affiliation .= " (" . join(", ", @tmp) . ")";
                                }
                        }
                $ligne = "AF : " . join(" ; ", @affiliations);
                push(@lignes, $ligne);
                }
        }

# Champ DT
my %host = ();
if ( $top{'host'} ) {
        %host = %{$top{'host'}};
        }
if ( $top{'genre'} or $host{'genre'} ) {
        $ligne = "DT : " . join(" ; ", map {"\u$_";} @{$host{'genre'}}, @{$top{'genre'}});
        push(@lignes, $ligne);
        }

# Champ SO
my @tmp = ();
push(@tmp, $host{'title'}) if $host{'title'};
# ISSN ou ISBN
if ( $host{'issn'} ) {
        push(@tmp, "ISSN ". ${$host{'issn'}}[0]);
        }
elsif ( $host{'isbn'} ) {
        push(@tmp, "ISBN ". ${$host{'isbn'}}[0]);
        }
# Choix de la date à afficher
if ( $top{'copyrightDate'} ) {
        push(@tmp, $top{'copyrightDate'});
        }
elsif ( $top{'publicationDate'} ) {
        push(@tmp, $top{'publicationDate'});
        }
elsif ( $host{'copyrightDate'} ) {
        push(@tmp, $host{'copyrightDate'});
        }
elsif ( $host{'publicationDate'} ) {
        push(@tmp, $host{'publicationDate'});
        }
if ( $host{'volume'} ) {
        push(@tmp, "vol. $host{'volume'}");
        }
if ( $host{'issue'} ) {
        push(@tmp, "n° $host{'issue'}");
        }
if ( $host{'pages'} ) {
        my %pages = %{$host{'pages'}};
        if ( $pages{'first'} ) {
                my $tmp = "p. $pages{'first'}";
                if ( $pages{'last'} and $pages{'last'} ne $pages{'first'} ) {
                        $tmp .= "-$pages{'last'}";
                        }
                push(@tmp, $tmp);
                }
        elsif ( $pages{'total'} ) {
                push(@tmp, "$pages{'total'} p.");
                }
        }
if ( @tmp ) {
        $ligne = "SO : " . join(" ; ", @tmp);
        push(@lignes, $ligne);
        }

# Champ LA
if ( $top{'language'} ) {
        foreach my $langue (@{$top{'language'}}) {
                if ( $langue{$langue} ) {
                        $langue = $langue{$langue};
                        }
                else    {
                        $langue = "\u$langue";
                        }
                }
        $ligne = "LA : " . join(" ; ", @{$top{'language'}});
        push(@lignes, $ligne);
        }

# Champ AB
if ( $top{'abstract'} ) {
        $top{'abstract'} =~ s/^\s*Abstract\s?:\s+//io;
        push(@lignes, "AB : $top{'abstract'}");
        }

# Champ CC
if ( $top{'categories'} ) {
        my %categories = %{$top{'categories'}};
        if ( $categories{'wos'} ) {
                my @wos = @{$categories{'wos'}};
                if ( @wos ) {
                        $ligne = "CC : " . join(" ; ", map {s/^(\d+ - )(\w)/\u$2/o; $_;} @wos);
                        push(@lignes, $ligne);
                        }
                }
        }

# Champs FD, ED, OD
if ( $top{'subject'} ) {
        my %kw = ();
        my @subjects = @{$top{'subject'}};
        foreach my $subject (@subjects) {
                my %keyword = %{$subject};
                if ( $keyword{'lang'} =~ /^fre\z/io ) {
                        push(@{$kw{'fre'}}, $keyword{'value'});
                        }
                elsif ( $keyword{'lang'} =~ /^eng\z/io ) {
                        push(@{$kw{'eng'}}, $keyword{'value'});
                        }
                else    {
                        push(@{$kw{'mul'}}, $keyword{'value'});
                        }
                }
        if ( defined $kw{'fre'} and @{$kw{'fre'}} ) {
                $ligne = "FD : " . join(" ; ", @{$kw{'fre'}});
                push(@lignes, $ligne);
                }
        if ( defined $kw{'eng'} and @{$kw{'eng'}} ) {
                $ligne = "ED : " . join(" ; ", @{$kw{'eng'}});
                push(@lignes, $ligne);
                }
        if ( defined $kw{'mul'} and @{$kw{'mul'}} ) {
                $ligne = "OD : " . join(" ; ", @{$kw{'mul'}});
                push(@lignes, $ligne);
                }
        }

# Champs FG, EG, OG
if ( $host{'subject'} ) {
        my %kw = ();
        my @subjects = @{$host{'subject'}};
        foreach my $subject (@subjects) {
                my %keyword = %{$subject};
                if ( $keyword{'lang'} =~ /^fre\z/io ) {
                        push(@{$kw{'fre'}}, $keyword{'value'});
                        }
                elsif ( $keyword{'lang'} =~ /^eng\z/io ) {
                        push(@{$kw{'eng'}}, $keyword{'value'});
                        }
                else    {
                        push(@{$kw{'mul'}}, $keyword{'value'});
                        }
                }
        if ( defined $kw{'fre'} and @{$kw{'fre'}} ) {
                $ligne = "FG : " . join(" ; ", @{$kw{'fre'}});
                push(@lignes, $ligne);
                }
        if ( defined $kw{'eng'} and @{$kw{'eng'}} ) {
                $ligne = "EG : " . join(" ; ", @{$kw{'eng'}});
                push(@lignes, $ligne);
                }
        if ( defined $kw{'mul'} and @{$kw{'mul'}} ) {
                $ligne = "OG : " . join(" ; ", @{$kw{'mul'}});
                push(@lignes, $ligne);
                }
        }

# # Champ AI (Automatic Indexing)
# if ( $indexation and $top{'keywords'} ) {
#         my %keywords = %{$top{'keywords'}};
#         if ( defined $keywords{'teeft'} ) {
#                 my @tmp = sort {length($a) <=> length($b) or $a cmp $b} @{$keywords{'teeft'}};
#                 my %tmp = ();
#                 for (my $nb = 0 ; $nb < $#tmp ; $nb ++) {
#                         if ( grep(/\b$tmp[$nb]\b/, @tmp[$nb + 1 .. $#tmp]) == 0 ) {
#                                 $tmp{$tmp[$nb]} ++;
#                                 }
#                         }
#                 $ligne = "AI : " . join(" ; ", grep {defined $tmp{$_}} @{$keywords{'teeft'}});
#                 push(@lignes, $ligne);
#                 }
#         }

# Champ LO
$ligne = "NO : ISTEX $top{'id'}";
@tmp = ();
if ( $top{'pii'} ) {
        foreach my $item (@{$top{'pii'}}) {
                push(@tmp, "PII $item");
                }
        }
if ( $top{'pmid'} ) {
        foreach my $item (@{$top{'pmid'}}) {
                push(@tmp, "PMID $item");
                }
        }
if ( $top{'doi'} ) {
        foreach my $item (@{$top{'doi'}}) {
                push(@tmp, "DOI $item");
                }
        }
if ( @tmp ) {
        $ligne = "LO : " . join(" ; ", @tmp);
        push(@lignes, $ligne);
        }

return decoupe(@lignes);
}

sub decoupe
{
my @lignes = @_;
my @final = ();

foreach my $ligne (@lignes) {
        while ( length($ligne) > 78 ) {
                my $debut = "";
                if ( $ligne =~ /^.{40,77}\s/ ) {
                        $debut = $&;
                        $ligne = "     " . $';
                        }
                else    {
                        $debut = substr($ligne, 0, 78);
                        $ligne = "     " . substr($ligne, 78);
                        }
                push(@final, $debut);
                }
        push(@final, $ligne);
        }

return @final;
}

sub decoupe2
{
my $ligne = shift;
my @final = ();


while ( length($ligne) > 63 ) {
        my $debut = "";
        if ( $ligne =~ /^.{30,62}\s/ ) {
                $debut = $&;
                $ligne = $';
                }
        else    {
                $debut = substr($ligne, 0, 63);
                $ligne = substr($ligne, 78);
                }
        push(@final, $debut);
        }
push(@final, $ligne);

$ligne = join("\n" . " " x 15, @final) . "\n";

return $ligne;
}

sub total
{
my $fichier = shift;

my $istex = 0;
my $nombre = 0;

open(TTL, "<:utf8", $fichier) or die "$!,";
while(<TTL>) {
        if ( /^\[ISTEX\]\s*/o ) {
                $istex = 1;
                }
        elsif (/^\[.+?\]\s*/o) {
                $istex = 0;
                }
        elsif ($istex and /^ark +/o) {
                $nombre ++;
                }
        elsif ($istex and /^id +/o) {
                $nombre ++;
                }
        }
close TTL;

return $nombre;
}

sub nettoye
{
my $signal = shift;

if ( fileno(TMP) ) {
        close TMP;
        }
if ( -f "$tmpfile" ) {
        die "Impossible de supprimer \"$tmpfile\" : $!," if not unlink $tmpfile;
        }

if ( $signal =~ /^\d+\z/ ) {
        exit $signal;
        }
if ( $signal ) {
        print STDERR "Signal SIG$signal détecté\n";
        exit 9;
        }
else    {
        exit 0;
        }
}


__DATA__

##
## Liste des codes langues (ISO 639)
## NE PAS ÉDITER !
##

% LANGUES

AFR	Afrikaans
ALB	Albanais
AMH	Amharique
ARA	Arabe
ARM	Arménien
AZE	Azerbaïdjanais
BAK	Bachkir
BAS	Basque
BEL	Biélorusse
BEN	Bengali
BER	Berbère
BRE	Breton
BUL	Bulgare
BUR	Birman
CAM	Cambodgien
CAT	Catalan
CHI	Chinois
CRO	Croate
CZE	Tchèque
DAN	Danois
DUT	Néerlandais
ENG	Anglais
ESK	Eskimo
ESP	Espéranto
EST	Estonien
FAR	Feroien
FIN	Finnois
FLE	Flamand
FRE	Français
FRI	Frison
GAE	Gaélique
GEO	Géorgien
GER	Allemand
GRC	Grec (ancien)
GRE	Grec (moderne)
GUA	Guarani
GUJ	Goujrati
HAU	Hausa
HEB	Hébreu
HIN	Hindi
HUN	Hongrois
ICE	Islandais
ILO	Igbo
IND	Indonésien
INT	Interlingua
IRI	Irlandais
ITA	Italien
JAP	Japonais
JPN	Japonais
KAZ	Kazakh
KIR	Kirghiz
KON	Kongo
KOR	Coréen
KUR	Kurde
LAO	Laotien
LAP	Lapon
LAT	Latin
LAV	Letton
LIT	Lithuanien
LUB	Louba
MAC	Macédonien
MAY	Malais
MLA	Malgache
MOL	Moldave
MON	Mongol
MUL	Multilingue
NOR	Norvégien
PAN	Pendjabi
PER	Persan
POL	Polonais
POR	Portugais
PRO	Provencal
PUS	Pachto
QUE	Quechua
ROH	Romanche
RUM	Roumain
RUS	Russe
SER	Serbe
SHO	Chona
SLO	Slovaque
SLV	Slovène
SNH	Cingalais
SPA	Espagnol
SWA	Swahili
SWE	Suédois
TAG	Tagal
TAJ	Tamoul
THA	Thaï
TUK	Turkmène
TUR	Turc
UKR	Ukrainien
UND	Inconnue
URD	Ourdou
UZB	Ouzbek
VIE	Vietnamien
WEL	Gallois
WOL	Wolof
YOR	Yorouba

% FIN
