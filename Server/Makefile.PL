use ExtUtils::MakeMaker;

my $GTOP_LIB = "";
if (my $path = $ENV{GTOP_LIB}) {
    $GTOP_LIB = "-L$path ";
}
my $GTOP_INCLUDE = "";
if (my $path = $ENV{GTOP_INCLUDE}) {
    $GTOP_INCLUDE = "-I$path ";
}

chomp(my $ginc = `glib-config --cflags`);

open FH, ">server_config_flags.h" or die "open server_config.h : $!";
open CONST, ">constants.c" or die "open constants.c: $!";

my @flags = qw(NONE INIT DEBUG VERBOSE NO_DAEMON NO_FORK CHANGED_UID);
my $bits = 0;
for my $flag (@flags) {
    print FH <<EOF;
#define GTOP_Sf_${flag} $bits
#define GTOP_S_${flag}     (glibtop_server_config->flags & GTOP_Sf_$flag)
#define GTOP_S_${flag}_on  (glibtop_server_config->flags |= GTOP_Sf_$flag)
#define GTOP_S_${flag}_off (glibtop_server_config->flags &= ~GTOP_Sf_$flag)

EOF
    print CONST qq{   newCONSTSUB(stash, "$flag", newSViv(GTOP_Sf_${flag}));\n};
    if ($bits < 2) {
	$bits++;
    }
    else {
	$bits *= 2;
    }
}

close FH;
close CONST;

my %config = get_glibtop_config();

WriteMakefile(
    NAME => "GTop::Server",
    VERSION_FROM => "Server.pm",
    INC => join(" ", $GTOP_INCLUDE, $ginc, $config{incs}),
    LIBS => [join(" ", $GTOP_LIB, $config{libs})],
    OBJECT => 'io.o main.o gnuserv.o version.o access.o Server.o',
    clean   => {
       FILES => "server_config_flags.h constants.c",
    },
);


# get libgtop CFLAGS/LIBS across 1.x-2.x versions
sub get_glibtop_config {
    my %c = ();

    if (system('pkg-config --exists libgtop-2.0') == 0) {
        # 2.x
        chomp($c{incs} = qx|pkg-config --cflags libgtop-2.0|);
        chomp($c{libs} = qx|pkg-config --libs   libgtop-2.0|);

        # 2.0.0 bugfix
        chomp(my $libdir = qx|pkg-config --variable=libdir libgtop-2.0|);
        $c{libs} =~ s|\$\(libdir\)|$libdir|;
    }
    elsif (system('gnome-config --libs libgtop') == 0) {
        chomp($c{incs} = qx|gnome-config --cflags libgtop|);
        chomp($c{libs} = qx|gnome-config --libs   libgtop|);

        # buggy ( < 1.0.9?) versions fixup
        $c{incs} =~ s|^/|-I/|;
        $c{libs} =~ s|^/|-L/|;
    }

    return %c;
}
