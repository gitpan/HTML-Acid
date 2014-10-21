use strict;
use warnings;
use Carp;
use Test::More;
use Test::NoWarnings;
use Test::Differences;
use HTML::Acid;
use Readonly;
use File::Basename;
use Benchmark qw(timethis);
use lib qw(t/lib);
use utils;

Readonly my @INPUT_FILES => glob 't/in/??-*';
Readonly my $MINIMUM_TIME => 10;
Readonly my $MINIMUM_ITERS => 200*$MINIMUM_TIME;
plan tests => 7+@INPUT_FILES;

my $acid = HTML::Acid->new;
isa_ok($acid, 'HTML::Acid', 'is a HTML::Acid');
isa_ok($acid, 'HTML::Parser', 'is a HTML::Parser');
ok($acid->can('burn'), 'Acid can burn.');
is($acid->burn(''), '', 'really trivial stuff');
is($acid->burn('blah'), "<p>blah</p>\n", 'really trivial blah');
is($acid->burn('<p> </p>'), "", 'empty para');

foreach my $input_file (@INPUT_FILES) {
    subtest $input_file => sub {
        plan tests => 3;
        my $input = utils::slurp_encode($input_file);
        my $basename = basename $input_file;
        my $expected = utils::slurp_encode("t/out/$basename");
        my $actual = $acid->burn($input);
        eq_or_diff($actual, $expected, "expected - $basename");
        $actual = $acid->burn($actual);
        eq_or_diff($actual, $expected, "idempotency - $basename");

        if ($ENV{TEST_AUTHOR}) {
            my $benchmark = timethis(-$MINIMUM_TIME, sub {
                my $t_acid = HTML::Acid->new;
                my $t_actual = $t_acid->burn($input);
                croak "failed" if $t_actual ne $expected;
            });
            ok($benchmark->iters > $MINIMUM_ITERS,
                "minimal iterations - $basename");
        }
        else {
            pass('set TEST_AUTHOR=1 for timings');
        }
    }
}

