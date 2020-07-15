
haXe client for Shoutcast/Icecast

Haxe library for listening to Icecast and Shoutcast (v1 tested, v2 should work) streams, MP3/AAC+, and NSV video (VP6/AVC video)

Initial upload - lots of cleaning up to do

NOTE: depends on hsl-1 and feffects haxe libraries

Flash only for playback - this also sort of works in neko, without producing any sound.

In fact, the core of this library was born from a rewrite of haxevideo (target platform is Neko in case you didn't know about haxevideo) adding shoutcast SERVER functionality (both source and client) with the resulting source stream being available to flash clients as if they are connected to a FlashMediaServer ... the ProtocolSource.hx protocol was actually the first that existed in a way.