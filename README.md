# RebuildRawPNGExtractedFromPDF

    This is a very dirty script / app hack that will allow you to re-extract the raw png's in your pdf (put there by things like img2pdf py) and re-construct them to be identical or mostly identical to the originals.

    I noticed that when reextracting raw pdf object data, that if you inserted JP2 files to begin with that the files will be byte for byte identical when inserted in the pdf objects. However, if you use a program like img2pdf to insert raw png into the objects instead, their header/footer and chunk header/footers are stripped.

    Apps like mutool will reconstruct the png properly as well, if you just want to get extracting without all the hassle, but I was interested in making sure that no "loss" was occurring due to re-encoding of any kind so I wasted my time on this. 

    It mostly works by a modified copy of png-debugger to determine the correct chunk header locations and correct crc's.
    
    This is super raw, and worked for my purposes (rebuilding raw png's extracted from pdf that match the filehashes of the originals).  I leave it here in the hopes that it will be useful to someone else in the future (why oh why did I do any of this in bash?!?!?)
    
    Everything is in the one .bash script.  The other things are the modified tool dependencies (and code).  There are other tools that the script uses, and specifically the version of pdfimages must have the -raw option to be useful (or the -all option, but I couldn't find code like that anywhere)
