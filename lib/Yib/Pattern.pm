package Yib::Pattern;
use Moo;

has pattern => (
    is => 'ro',
    required => 1,
);

has trigger => (
    is => 'ro',
    required => 1,
);

has channel => (
    is => 'ro',
    required => 1,
);

has name => (
    is => 'ro',
    required => 1,
);
1;
