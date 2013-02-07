package Yib::Soundbank;
use Moo;
use Carp;
use SDL;
use SDL::Audio;
use SDL::Mixer;
use SDL::Mixer::Samples;
use SDL::Mixer::Channels;
use SDL::Mixer::Music;

#SDL::init(SDL_INIT_AUDIO);
use SDL::Mixer;
 
my $init_flags = SDL::Mixer::init( MIX_INIT_MP3 | MIX_INIT_MOD | MIX_INIT_FLAC | MIX_INIT_OGG );
 
print("We have MP3 support!\n")  if $init_flags & MIX_INIT_MP3;
print("We have MOD support!\n")  if $init_flags & MIX_INIT_MOD;
print("We have FLAC support!\n") if $init_flags & MIX_INIT_FLAC;
print("We have OGG support!\n")  if $init_flags & MIX_INIT_OGG;

#unless ( SDL::Mixer::open_audio( 44100, AUDIO_S16SYS, 2, 4096 ) == 0 ) {
unless ( SDL::Mixer::open_audio( 44100, AUDIO_S16SYS, 2, 500 ) == 0 ) {
    Carp::croak "Cannot open audio: " . SDL::get_error();
}

my %cache;
sub play_wav {
    my ( $self, $file, $channel ) = @_;
    $channel ||= -1;
    confess "missing channel" unless $channel;
    unless( $cache{$file} ) {
        warn "$file not cached";
        $cache{$file} = SDL::Mixer::Samples::load_WAV($file) or die SDL::get_error();
    }
#    my $playing_channel = SDL::Mixer::Channels::play_channel( -1, $cache{$file}, 0 );
    my $playing_channel = SDL::Mixer::Channels::play_channel( $channel, $cache{$file}, 0 );
}
sub play_music {
    my($self,$file) = @_;
    my $music = SDL::Mixer::Music::load_MUS($file) or die SDL::get_error();
    SDL::Mixer::Music::play_music($music,0);

}

sub DESTROY {
    SDL::Mixer::close_audio();
    SDL::quit;
}

1;
