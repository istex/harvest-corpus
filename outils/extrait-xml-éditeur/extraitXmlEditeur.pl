#!/usr/bin/env perl


# Déclaration des pragmas
use strict;
use utf8;
use open qw/:std :utf8/;

# Appel des modules externes de base
use Encode qw(decode_utf8 encode_utf8 is_utf8);
use Getopt::Long;

my ($programme) = $0 =~ m|^(?:.*/)?(.+)|;
my $usage = "Usage : \n" .
            "    $programme -r répertoire [ -e expression_régulière ] [ -l log ] [ -s ] \n" .
            "    $programme -f fichier [ -e expression_régulière ] [ -l log ] [ -s ] \n" .
            "    $programme -h \n";

my $version     = "1.5.3";
my $dateModif   = "28 Septembre 2018";

# Variables nécessaires pour les options
my $aide       = undef;
my $expression = undef;
my $fichier    = undef;
my $log        = undef;
my $motif      = undef;
my $nombre     = undef;
# my $pdf        = undef;
my $repertoire = undef;
my $supprime   = 0;

# integre les options que l'on peut donner en lancant le programme
eval	{
	$SIG{__WARN__} = sub {usage(1);};
	GetOptions(
		"expression=s"  => \$expression,
		"fichier=s"     => \$fichier,
		"help"          => \$aide,
		"log=s"         => \$log,
		"motif=s"       => \$motif,
		"nombre=i"      => \$nombre,
# 		"pdf"           => \$pdf,
		"repertoire=s"  => \$repertoire,
		"supprime"      => \$supprime,
		);
	};
$SIG{__WARN__} = sub {warn $_[0];};

if ( $aide ) {
	print "\nProgramme : \n";
	print "   “$programme”, version $version ($dateModif)\n";
	print "    Outil qui permet d'extraire le fichier XML éditeur d’une \n";
	print "    archive ZIP et de le renommer pour lui donner la même racine \n";
	print "    que le document auquel il fait référence. Il travaille sur \n";
	print "    un fichier ou sur un répertoire de fichiers “.zip”. \n\n";
	print "$usage\n";
	print "Options : \n";
	print "    -e  indique l’expression régulière (compatible Perl) à utiliser \n";
	print "        pour identifier le fichier XML éditeur dans l’archive “.zip” \n";
	print "        (à mettre entre simples ou doubles quotes) \n";
#	print "        le fichier XML éditeur dans l’archive “.zip” \n";
	print "    -f  donne le nom du fichier “.zip” contenant le fichier XML éditeur \n";
	print "        à extraire \n";
	print "    -h  affiche cette aide \n";
	print "    -l  indique le nom du fichier “log” où le programme écrit les \n";
	print "        messages d’erreur ou autres (N.B. : ce fichier n’est pas \n";
	print "        écrasé lorsque l’on relance le programme) \n";
	print "    -r  indique le nom du répertoire où se trouvent les fichiers \n";
	print "        “.zip” d’où doivent être extraits les fichiers XML éditeurs \n";
	print "    -s  supprime le fichier “.zip” si le fichier XML a été extrait \n";
	print "        avec succès \n\n";
	print "Exemples : \n";
	print "    $programme -r Arthropodes -l logExtraitXml.txt \n";
	print "    $programme -f Arthropodes/arthropodes_000125.zip -e '\\.article' \n";
	print "    \n";

	
	exit 0;
	}

usage(2) if not $repertoire and not $fichier;

if ( $expression ) {
	$expression = qr/$expression/;
	}

if ( $log ) {
	if ( -f $log ) {
		open(LOG, ">>:utf8", $log) or die "$!,";
		}
	else	{
		open(LOG, ">:utf8", $log) or die "$!,";
		}
	my @time = localtime();
	my $jour = (qw(Dimanche Lundi Mardi Mercredi Jeudi Vendredi Samedi))[$time[6]];
	my $mois = (qw(Janvier Février Mars Avril Mai juin Juillet Août Septembre Octobre Novembre Décembre))[$time[4]];
	my $annee = $time[5] + 1900;
	my $date = "$jour $time[3] $mois $annee ";
	$date .= sprintf("%02d:%02d:%02D", $time[2], $time[1], $time[0]);
	if ( $repertoire ) {
		print LOG "\n===> $repertoire <=== $date\n\n";
		}
	elsif ( $fichier ) {
		print LOG " - $fichier : $date\n";
		}
	}
else	{
	open(LOG, ">&STDERR") or die "$!,";
	}

if ( $repertoire ) {
	if ( not -d $repertoire ) {
		print STDERR "Erreur : répertoire \"$repertoire\" absent\n";
		exit 3;
		}

	my @restant = ();
	if ( defined $nombre ) {
		if ($nombre < 1 ) {
			print STDERR "Erreur : le nombre de fichier doit être un entier positif\n";
			exit 4;
			}
		foreach my $valeur (1 .. $nombre) {
			$restant[$valeur] = 1;
			}
		}


	opendir(DIR, $repertoire) or die "$!,";
	my @fichiers = ();
	if ( defined $motif ) {
		@fichiers = sort grep(/^${motif}_?\d+\.zip\z/, readdir DIR);
		}
	else	{
		@fichiers = sort grep(/^.+\.zip\z/, readdir DIR);
		}
	closedir DIR;

	foreach my $fichier (@fichiers) {
		my $base   = "";
		my $valeur = "";
		if ( defined $motif ) {
			($base, $valeur) = $fichier =~ /^(${motif}_?(\d+))\.zip/o;
			$restant[$valeur] = 0;
			}
		elsif ( $fichier =~ /^([0-9A-F]{40})\.zip/o ) {
			$base = substr($fichier, 0, 40);
			}
		elsif ( $fichier =~ /^(.+?_?(\d+))\.zip/o ){
			($base, $valeur) = ($1, $2);
			}
		else	{
			($base) = $fichier =~ /^(.+)\.zip/o;
			}
		if ( -f "$repertoire/$base.xml" ) {
			next;
			}
		traite($repertoire, $fichier, $base);
		}

	if ( defined $nombre ) {
		my $absent = 0;
		foreach my $valeur (1 .. $nombre) {
			if ( $restant[$valeur] ) {
				$absent ++;
				print LOG "Pas de fichier ZIP pour document n° $valeur\n";
				}
			}
		if ( $absent ) {
			print LOG "Total : $absent fichiers ZIP absents\n";
			}
		}

	}

elsif ( $fichier ) {
	my ($chemin, $nom, $base) = $fichier =~ m|^(.*/)?((.+)\.[Zz][Ii][Pp])|o;
	$chemin = "." if not $chemin;
	traite($chemin, $nom, $base);
	}


exit 0;


sub usage
{
my $code = shift;

print STDERR "\n$usage";

exit $code;
}

sub erreur
{
my ($message, $code) = @_;

print LOG "$message\n";

exit $code;
}

sub traite
{
my ($directory, $file, $base) = @_;

my @pdf    = ();
my @xml    = ();
my $type   = 0;

open(INP, "unzip -l $directory/$file 2>&1 |") or die "$!,";
while(<INP>) {
	s/^\s+//o;
	s/[\n\r]+//o;
	if ( /\.pdf\s*$/io ) {
		my @tmp = split(/\s+/, $_, 4);
		push(@pdf, $tmp[$#tmp]);
		erreur("Erreur sur fichier \"$file\"", 5) if $tmp[$#tmp] !~ /\.pdf\z/i;
		}
	elsif ( /\.xml\s*$/io ) {
		my @tmp = split(/\s+/, $_, 4);
		push(@xml, $tmp[$#tmp]);
		erreur("Erreur sur fichier \"$file\"", 6) if $tmp[$#tmp] !~ /\.xml\z/i;
		}
	elsif ( /\.xml\b/io ) {
		my @tmp = split(/\s+/, $_, 4);
		push(@xml, $tmp[$#tmp]);
		erreur("Erreur sur fichier \"$file\"", 6) if $tmp[$#tmp] !~ /\.xml\b/i;
		}
	elsif ( /\.nxml\s*$/io ) {
		my @tmp = split(/\s+/, $_, 4);
		push(@xml, $tmp[$#tmp]);
		erreur("Erreur sur fichier \"$file\"", 6) if $tmp[$#tmp] !~ /\.nxml\z/i;
		}
	elsif ( $expression and /$expression\s*$/io ) {
		my @tmp = split(/\s+/, $_, 4);
		push(@xml, $tmp[$#tmp]);
		erreur("Erreur sur fichier \"$file\"", 6) if $tmp[$#tmp] !~ /$expression\z/i;
		}
	elsif ( /unzip: +cannot find zipfile directory/o ) {
		print LOG "Le fichier \"$file\" n'est pas une archive ZIP\n";
		$type = 1;
		last;
		}
	elsif ( /: +zipfile is empty/o ) {
		print LOG "L'archive ZIP \"$file\" est vide\n";
		$type = 2;
		last;
		}
	}
close INP;

return $type if $type;

if ( $#pdf > 0 ) {
	my @tmp = ();
	foreach my $pdf (@pdf) {
		my ($debut) = $pdf =~ /^(.+)\.pdf/io;
		if (grep(/^$debut.xml\z/i, @xml) > 0) {
			push(@tmp, $pdf);
			next;
			}
		$debut =~ s/pdf/xml/o;
		if (grep(/^$debut.xml\z/, @xml) > 0) {
			push(@tmp, $pdf);
			next
			}
		$debut =~ s/PDF/XML/o;
		if (grep(/^$debut.xml\z/i, @xml) > 0) {
			push(@tmp, $pdf);
			next
			}
		($debut) = $pdf =~ m|^(?:.+/)?(.+)\.pdf|io;
		if (grep(/\b$debut.xml\b/i, @xml) > 0) {
			push(@tmp, $pdf);
			}
		}
	# Dédoublonnage
	if ( $#tmp == 0 ) {
		@pdf = @tmp;
		}
	elsif ( $#tmp > 0 ) {
		print LOG "Attention : PDF multiples pour \"$file\"\n";
		return 3;
		}
	elsif ( $#xml < 0 or $#xml > 0 ) {
		print LOG "Attention : cas bizarre pour \"$file\"\n";
		return 4;
		}
	}

if ( $#pdf == 0 ) {
	my ($debut) = $pdf[0] =~ /^(.+)\.pdf/io;
	my @cibles = grep(/^$debut.xml\z/i, @xml);
	if ( $#cibles == 0 ) {
		my ($racine) = $cibles[0] =~ m|^(?:.*/)?(.+)\.xml\z|io;
		my $retour = system "unzip -jo \"$directory/$file\" \"$cibles[0]\" > /dev/null";
		if ( $retour ) {
			my $erreur = ($retour - ($retour % 256)) / 256;
			print "$programme : erreur $erreur d’ \"unzip\" pour fichier \"$file\"\n";
			return 5;
			}
		if ( -f "$racine.xml" ) {
			$retour = system "mv \"$racine.xml\" \"$directory/$base.xml\"";
			efface("$directory/$file") if $supprime and not $retour;
			}
		elsif ( -f "$racine.XML" ) {
			$retour = system "mv \"$racine.XML\" \"$directory/$base.xml\"";
			efface("$directory/$file") if $supprime and not $retour;
			}
		else	{
			print LOG "Erreur : pas de fichier \"$racine.xml\" extrait de \"$file\"\n";
			}
		}
	else	{
		if ( $debut =~ /\bpdf\b/o ) {
			$debut =~ s/pdf/xml/o;
			}
		if ( $debut =~ /\bPDF\b/o ) {
			$debut =~ s/PDF/XML/o;
			}
		@cibles = grep(/^$debut.xml\z/i, @xml);
		if ( $#cibles == 0) {
			my ($racine) = $cibles[0] =~ m|^(?:.*/)?(.+)\.xml\z|o;
			my $retour = system "unzip -jo \"$directory/$file\" \"$cibles[0]\" > /dev/null";
			if ( $retour ) {
				my $erreur = ($retour - ($retour % 256)) / 256;
				print "$programme : erreur $erreur d’ \"unzip\" pour fichier \"$file\"\n";
				return 5;
				}
			if ( -f "$racine.xml" ) {
				$retour = system "mv \"$racine.xml\" \"$directory/$base.xml\"";
				efface("$directory/$file") if $supprime and not $retour;
				}
			elsif ( -f "$racine.XML" ) {
				$retour = system "mv \"$racine.XML\" \"$directory/$base.xml\"";
				efface("$directory/$file") if $supprime and not $retour;
				}
			else	{
				print LOG "Erreur : pas de fichier \"$racine.xml\" extrait de \"$file\"\n";
				}
			}
		elsif ( $#xml == 0 ) {
			if ( $expression and $xml[0] =~ m|^((?:.*/)?(.*$expression))| ) {
				my $entree = $1;
				my $xml    = $2;
				my $retour = system "unzip -jo \"$directory/$file\" \"$entree\" > /dev/null";
				if ( $retour ) {
					my $erreur = ($retour - ($retour % 256)) / 256;
					print "$programme : erreur $erreur d’ \"unzip\" pour fichier \"$file\"\n";
					return 5;
					}
				if ( -f "$xml" ) {
					$retour = system "mv \"$xml\" \"$directory/$base.xml\"";
					efface("$directory/$file") if $supprime and not $retour;
					}
				else	{
					print LOG "Erreur : pas de fichier \"$xml\" extrait de \"$file\"\n";
					}
				}
			else	{
				my ($entree, $xml) = $xml[0] =~ m|^((?:.*/)?(.+\.n?xml.*))|io;
				my $retour = system "unzip -jo \"$directory/$file\" \"$entree\" > /dev/null";
				if ( $retour ) {
					my $erreur = ($retour - ($retour % 256)) / 256;
					print "$programme : erreur $erreur d’ \"unzip\" pour fichier \"$file\"\n";
					return 5;
					}
				if ( -f "$xml" ) {
					$retour = system "mv \"$xml\" \"$directory/$base.xml\"";
					efface("$directory/$file") if $supprime and not $retour;
					}
				else	{
					print LOG "Erreur : pas de fichier \"$xml\" extrait de \"$file\"\n";
					}
				}
			}
		else	{
			print LOG "Pas de XML \"$debut.xml\" pour \"$file\"\n";
			}
		}
	}
elsif ( $#xml == 0 ) {
	my ($entree, $xml) = $xml[0] =~ m|^((?:.*/)?(.+\.xml))|;
	my $retour = system "unzip -jo \"$directory/$file\" \"$entree\" > /dev/null";
	if ( $retour ) {
		my $erreur = ($retour - ($retour % 256)) / 256;
		print "$programme : erreur $erreur d’ \"unzip\" pour fichier \"$file\"\n";
		return 5;
		}
	if ( -f "$xml" ) {
		$retour = system "mv \"$xml\" \"$directory/$base.xml\"";
		efface("$directory/$file") if $supprime and not $retour;
		}
	else	{
		print LOG "Erreur : pas de fichier \"$xml\" extrait de \"$file\"\n";
		}
	}
elsif ( $#pdf > 0 ) {
	print LOG "Attention : encore des PDF multiples pour \"$file\"\n";
	}
else	{
	print LOG "Attention : autre cas bizarre pour \"$file\"\n";
	}

return 0;
}

sub efface
{
my $cible = shift;

my $rc = unlink $cible;

if ( not $rc ) {
	print LOG "Erreur : impossible de supprimer le fichier \"$cible\"\n";
	}
}
