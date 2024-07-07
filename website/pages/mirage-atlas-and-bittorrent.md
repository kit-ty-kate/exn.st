# Mirage, Atlas and BitTorrent
*a tale from the MirageOS hack retreat of spring 2024*

I've been coming to most [MirageOS retreat](https://retreat.mirage.io/) since 2017. Each time, had their share of new things to learn, things to share and experience.  
Usually my output from it was either not working, too niche, too intengible (discussion, learnings, ...) or too similar to a regular work day, for me to want to write a blog post.  
However, this time, i've done the couple things i wanted to do that i'm excited to share.

## Hiking in the Atlas

Being fond of hiking in the scottish highlands near where i live, this time around i decided to organize a day trip in the [High Atlas](https://en.wikipedia.org/wiki/High_Atlas).  
I scouted a hiking route using the [All Trails](https://www.alltrails.com/) map and confirmed viability by looking at YouTube videos of the hike.

The route starts from a lonely cafe in a valley 15mins away from [Imlil](https://en.wikipedia.org/wiki/Imlil,_Marrakesh-Safi) by taxi at 2300m, passing through a small tree plantation, then up to the first summit at 2700m. The walk is fairly straightforward but taxing due to the thin atmosphere at this altitude. Having arrived at the first summit and feeling partly ok we decided to continue following the ridge and up 100 more meters.

Being personally not used to high altitude i decided to stop at a small climbing section just before the top as i was feeling too light headed for it.  
The others continued, reached the summit and we all got back down with a total of 4 hours.  
I had a lot of fun.

<img alt="Toubkal and Imlil" src="toubkal-imlil.webp" width="30%">
<img alt="Aourirt n'ouassif" src="aourirt-n-ouassif.webp" width="30%">
<img alt="Towards Marrkesh" src="atlas-marrakesh.webp" width="30%">

## Mirage & BitTorrent

Coming to the retreat in had already a project in mind: a BitTorrent client.  
The reason for this is that my current torrent client [is developed by a known far right type guy](https://maia.crimew.gay/posts/meet-the-shitpoasters/).  
It would be my first actual implementation of an existing network-oriented spec and i was excited for it.

So on my first day i decided to look at the existing OCaml implementations such as [ocaml-bt](https://github.com/nojb/ocaml-bt/), [mldonkey](https://github.com/ygrek/mldonkey) or [tornado](https://github.com/fraidev/tornado), but they either were mostly unmaintained and i didn't manage to compile them, or they were using technologies unfit for Mirage.  
For those reasons and for the fun of it, i decided to implement yet another BitTorrent implementation.

Having not looked at the spec before, i was delighted to see that it looked very simple and very readable.  
The [spec](http://www.bittorrent.org/beps/bep_0003.html) is divided in 5 parts:
- a high level definition 
- a description of [bencode](https://en.wikipedia.org/wiki/Bencode), the main encoding used in torrent files and when sending messages
- a description of how to talk to the **tracker**, the main server keeping track of the list of peers
- 2 sections describing how to talk to the **peers**

All of this is written in a comprehensive language, which i feel is a far cry from other protocols' RFCs and alike.

### Implementation 

*The project is far from finished but it's currently able to download a full torrent. The source is available at: [kit-ty-kate/mirage-torrent](https://github.com/kit-ty-kate/mirage-torrent)*

#### Bencode

To implement Bencode, Hannes told me of a library by Rudi and co-maintained by c-cube called [bencode](https://github.com/rgrinberg/bencode), which worked perfectly (*with two exceptions which i'll mention in the next segment*)  
Using that library i was able to fully and correctly parse a torrent file in about a day without any issues.

#### Tracker

Next up: talking to the **tracker**. A tracker is a service connected to the internet whose task is to keep an up-to-date list of all the peers for one or several torrents.  
This part introduced 2 problems:
- the tracker wants a checksum of a **subset** of the torrent file. There are several ways to get this:
    - you can do it somewhat efficiently in 1 pass during parsing by adding the current character to a buffer and run the checksum algorithm on it incrementally. However the bencode library i'm using [lacked the API to do this](https://github.com/rgrinberg/bencode/issues/15)
    - or do it inefficiently by re-encoding the parsed subset and run the checksum algorithm on the whole thing. For this method to work you need to make sure the encoder and decoder are *isomorphic*, meaning running the decoder on the output of the encoder is guaranteed to produce the same value as what was originally given to the encoder. It turns out the bencode library wasn't but the reason for it was a [bug](https://github.com/rgrinberg/bencode/pull/16). Once fixed, i chose this solution for simplicity sake.
- The second problem was that, while testing using the Debian Tracker, i noticed that it did not quite respect the spec which [tells us](http://www.bittorrent.org/beps/bep_0003.html#trackers) that the response from the tracker should include the ID of each peers. The spec includes an extension called [compact mode](http://www.bittorrent.org/beps/bep_0023.html) which does not include the ID. I believe some trackers simply have the same representation for both modes as compact mode is wildly used according to the spec, and the ID isn't really needed. So to fix this issue i did the same and made the ID optional, and also implemented compact mode for the fun of it.

#### Peers

Once in possession of the list of peers received from the tracker, we can actually start talking the them (BitTorrent being a peer-to-peer protocol and all)

The spec tells us what shape the connection looks like: a header, then wait for messages bidirectionally, until the connection is severed.

Headers tell each peers which extensions the client supports and which chunks each peer has downloaded.  
Then each messages start with a fixed length integer indicating the size of the message to wait for, a 1 byte flag, then the content depending on the flag.

### The fun part begins

All the previous parts i described are pretty straightforward to understand and implement, however what i think makes this protocol interesting beyond being easy to learn and implement is how fun the main algorithm (scheduler) is:

**Using the main message system, you have full control on the way you implement the scheduler to download and upload data.**

Said scheduler is also tasked with managing and storing subchunks with regard to their base chunk (named "piece" in the spec).

## Conclusion

For those who are able to come, the MirageOS retreat is a treat of social interactions, full of learnings and experiences of all sorts. If you have the occasion, come. You can read on the experiences of others at the end of [the retreat page](https://retreat.mirage.io/)

The main thing i learned at that particular retreat is that BitTorrent is an ideal protocol to give to people who want to learn about protocols or just as a simple fun exercise when learning a language or whatever else.

Special thanks to Hannes, Yureka and Dinosaure who helped me on the BitTorrent implementation, as well as all the staff at Priscilla and everyone else who came.
