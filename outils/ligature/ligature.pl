#!/usr/bin/perl


# Déclaration des pragmas
use strict;
use utf8;
use open qw/:std :utf8/;

# Appel des modules externes de base
use Encode qw(decode_utf8 encode_utf8 is_utf8);
use Getopt::Long;

my ($programme) = $0 =~ m|^(?:.*/)?(.+)|;

# Variables pour les options
my $aide       = 0;
my $fichier    = "";
my $quiet      = 0;
my $repertoire = "";
my @extensions = ();


eval	{
	$SIG{__WARN__} = sub {usage(1);};
	GetOptions(
		"extension=s"  => \@extensions,
		"fichier=s"    => \$fichier,
		"help"         => \$aide,
		"quiet"        => \$quiet,
		"repertoire=s" => \$repertoire,
		);
	};
$SIG{__WARN__} = sub {warn $_[0];};

usage(2) if not $fichier and not $repertoire;

if ( $fichier ) {
	traite($fichier);
	}
elsif ( $repertoire ) {
        my @fichiers = ();
        opendir(DIR, $repertoire) or die "$!,";
	if ( @extensions ) {
		my $extensions = "(" . join("|", map {s/^\.//o; s/(\W)/\\$1/go; $_;} @extensions) . ")";
		@fichiers = grep(/\.$extensions\z/, grep(!/^\./o, readdir(DIR)));
		}
	else	{
		@fichiers = grep(!/^\./o, readdir(DIR));
		}
        closedir(DIR);
        foreach $fichier (@fichiers) {
                traite("$repertoire/$fichier");
                }
        }


exit 0;


sub usage
{
my $retour = shift;

print STDERR "Usage : $programme -r répertoire [ -e extension ]* [ -q ] \n";
print STDERR "        $programme -f fichier [ -q ] \n";
print STDERR "        $programme -h \n";

exit $retour;
}

sub traite
{
my $input = shift;

my $nbLignes = 0;
my $nbModifs = 0;
my $nom      = "";
my @lignes   = ();

if ( $input eq "-" ) {
	$nom = "STDIN";
	open(INP, "<&STDIN") or die "Impossible de dupliquer STDIN: $!,";
	binmode(INP, ":utf8");
	}
else	{
	($nom) = $input =~ m|^(?:.*/)?(.+)|;
	open(INP, "<:utf8", $input) or die "Impossible d’ouvrir $input en lecture : $!,";
	}

print STDERR " - $nom : " if not $quiet;

while(<INP>) {
	if ( /[\x{FB00}-\x{FB04}]/ ) {
		$nbLignes ++;
		$nbModifs += s/\x{FB00}/ff/go;
		$nbModifs += s/\x{FB01}/fi/go;
		$nbModifs += s/\x{FB02}/fl/go;
		$nbModifs += s/\x{FB03}/ffi/go;
		$nbModifs += s/\x{FB04}/ffl/go;
		}
	push(@lignes, $_);
	}
close INP;

if ( $input ne '-' and $nbModifs ) {
	open(OUT, ">:utf8", $input) or die "Impossible d’ouvrir $input en écriture : $!,";
	print OUT @lignes;
	}

printf(STDERR "%d modification(s) / %d ligne(s)\n", $nbModifs, $nbLignes) if not $quiet;
}
