#!/bin/bash

# The IHDR chunk must appear FIRST. It contains:

   # Width:              4 bytes Extracted from PDF metadata on object, not in raw object
   # Height:             4 bytes Extracted from PDF metadata on object, not in raw object
   # Bit depth:          1 byte  Extracted from PDF metadata on object, not in raw object
   # Color type:         1 byte  Extracted from PDF metadata on object, not in raw object
   # Compression method: 1 byte  Extracted from PDF metadata on object, not in raw object
   # Filter method:      1 byte  Extracted from PDF metadata on object, not in raw object
   # Interlace method:   1 byte  Extracted from PDF metadata on object, not in raw object

   # Color    Allowed    Interpretation
   # Type    Bit Depths
   
   # 0       1,2,4,8,16  Each pixel is a grayscale sample.
   
   # 2       8,16        Each pixel is an R,G,B triple.
   
   # 3       1,2,4,8     Each pixel is a palette index;
                       # a PLTE chunk must appear.
   
   # 4       8,16        Each pixel is a grayscale sample,
                       # followed by an alpha sample.
   
   # 6       8,16        Each pixel is an R,G,B triple,
                       # followed by an alpha sample.
					   
# The sample depth is the same as the bit depth except in the case of color type 3, in which the sample depth is always 8 bits.

# Compression method is a single-byte integer that indicates the method used to compress the image data. At present, only compression method 0 (deflate/inflate compression with a sliding window of at most 32768 bytes) is defined. All standard PNG images must be compressed with this scheme. The compression method field is provided for possible future expansion or proprietary variants. Decoders must check this byte and report an error if it holds an unrecognized code. See Deflate/Inflate Compression for details.

# Filter method is a single-byte integer that indicates the preprocessing method applied to the image data before compression. At present, only filter method 0 (adaptive filtering with five basic filter types) is defined. As with the compression method field, decoders must check this byte and report an error if it holds an unrecognized code. See Filter Algorithms for details.

# Interlace method is a single-byte integer that indicates the transmission order of the image data. Two values are currently defined: 0 (no interlace) or 1 (Adam7 interlace). See Interlaced data order for details. 
   
  #Width 00 00 04 00 1024
  #Height 00 00 06 00 1536
  #
  
  # sBIT Significant bits

# To simplify decoders, PNG specifies that only certain sample depths can be used, and further specifies that sample values should be scaled to the full range of possible values at the sample depth. However, the sBIT chunk is provided in order to store the original number of significant bits. This allows decoders to recover the original data losslessly even if the data had a sample depth not directly supported by PNG. We recommend that an encoder emit an sBIT chunk if it has converted the data from a lower sample depth.

# For color type 0 (grayscale), the sBIT chunk contains a single byte, indicating the number of bits that were significant in the source data.

# For color type 2 (truecolor), the sBIT chunk contains three bytes, indicating the number of bits that were significant in the source data for the red, green, and blue channels, respectively.

# For color type 3 (indexed color), the sBIT chunk contains three bytes, indicating the number of bits that were significant in the source data for the red, green, and blue components of the palette entries, respectively.

# For color type 4 (grayscale with alpha channel), the sBIT chunk contains two bytes, indicating the number of bits that were significant in the source grayscale data and the source alpha data, respectively.

# For color type 6 (truecolor with alpha channel), the sBIT chunk contains four bytes, indicating the number of bits that were significant in the source data for the red, green, blue, and alpha channels, respectively.

# Each depth specified in sBIT must be greater than zero and less than or equal to the sample depth (which is 8 for indexed-color images, and the bit depth given in IHDR for other color types).

# A decoder need not pay attention to sBIT: the stored image is a valid PNG file of the sample depth indicated by IHDR. However, if the decoder wishes to recover the original data at its original precision, this can be done by right-shifting the stored samples (the stored palette entries, for an indexed-color image). The encoder must scale the data in such a way that the high-order bits match the original data.

# If the sBIT chunk appears, it must precede the first IDAT chunk, and it must also precede the PLTE chunk if present.

# See Recommendations for Encoders: Sample depth scaling and Recommendations for Decoders: Sample depth rescaling. 

# This method normally returns pixel values with the bit depth they have in the source image, but when the source PNG has an sBIT chunk it is inspected and can reduce the bit depth of the result pixels; pixel values will be reduced according to the bit depth specified in the sBIT chunk (PNG nerds should note a single result bit depth is used for all channels; the maximum of the ones specified in the sBIT chunk. An RGB565 image will be rescaled to 6-bit RGB666).

# bitdepth specifies the bit depth of the source pixel values. Each source pixel value must be an integer between 0 and 2**bitdepth-1. For example, 8-bit images have values between 0 and 255. PNG only stores images with bit depths of 1,2,4,8, or 16. When bitdepth is not one of these values, the next highest valid bit depth is selected, and an sBIT (significant bits) chunk is generated that specifies the original precision of the source image. In this case the supplied pixel values will be rescaled to fit the range of the selected bit depth.

# The details of which bit depth / colour model combinations the PNG file format supports directly, are somewhat arcane (refer to the PNG specification for full details). Briefly: “small” bit depths (1,2,4) are only allowed with greyscale and colour mapped images; colour mapped images cannot have bit depth 16.

# For colour mapped images (in other words, when the palette argument is specified) the bitdepth argument must match one of the valid PNG bit depths: 1, 2, 4, or 8. (It is valid to have a PNG image with a palette and an sBIT chunk, but the meaning is slightly different; it would be awkward to press the bitdepth argument into service for this.)


#mapfile -t imagenumarray < <(mutool info ../combined.pdf | grep Images -A 1000000 | tail -n +2 | head -n -1 | sed 's/.*DevRGB (//'| sed 's/ .*//g')
mapfile -t widtharray < <(mutool info "$1" | grep Images -A 1000000 | tail -n +2 | head -n -1 | sed 's/^.*\] //' | sed 's/DevRGB.*//' | sed 's/x.*//g')
mapfile -t heightarray < <(mutool info "$1" | grep Images -A 1000000 | tail -n +2 | head -n -1 | sed 's/^.*\] //' | sed 's/DevRGB.*//' | sed 's/^.*x//g' | sed 's/ .*//g')
bitdep=$(mutool info "$1" | grep Images -A 1000000 | tail -n +2 | head -n 1 | sed 's/^.*\] //' | sed 's/DevRGB.*//' | sed 's/^[^ ]*//g' | sed 's/ //g' | sed 's/bpc//g')
bitdep=$(printf "%02x" $bitdep)

for ((i=0;i<${#widtharray[@]};++i))
do

	temp_file=$(mktemp)
	temp1=$(mktemp)
	temp2=$(mktemp)
	temp3=$(mktemp)

	width=$(printf "%08x" ${widtharray[$i]})
	height=$(printf "%08x" ${heightarray[$i]})
	
	PNGHEADERCONST='89504E470D0A1A0A'
	IHDRLength='0000000D' #always the same to accommodate the data listed above commented out IHDR chunk info
	IHDR='49484452'
	Width=$width
	Height=$height
	BitDepth=$bitdep
	ColorType='02'
	CompressionMethod='00'
	FilterMethod='00'
	InterfaceMethod='00'
	IHDRCRC='67E0ADFD'
	FirstSBITLength='00000003' # 3 (R+G+B) if color, 2 (B+W) if grayscale.  16 is max, is output by the mutool command as the 3rd variable as "bpc" bits per channel
	SBIT='73424954'
	BitDepthPerChannel=$bitdep$bitdep$bitdep #'080808' or $bitdep$bitdep for bw
	SBITCRC='DBE14FE0' #Should be computed, like the IDATCRC, png-debugger will tell you what to do.
	FirstIDATLength='00002000' # Needs to be computer, but can't be initially, should be populated with 0 and filled in after the determination of the location of the 3rd chunk.
	IDAT='49444154'
	
	currentpage=$(( $i + 1 ))
	
	currentfile=$(pdfimages -raw -list -f $currentpage -l $currentpage "$1" $temp_file | sed 's/:.*//g')
	
	echo "file="$currentfile"&page="$currentpage
	
	echo $PNGHEADERCONST$IHDRLength$IHDR$Width$Height$BitDepth$ColorType$CompressionMethod$FilterMethod$InterfaceMethod$IHDRCRC$FirstSBITLength$SBIT$BitDepthPerChannel$SBITCRC$FirstIDATLength$IDAT | xxd -ps -r | cat - $currentfile > $temp_file

	echo '000000000000000049454E44AE426082' | xxd -ps -r >> $temp_file #append footer, with blank unknown crc for previous chunk and unknown size for current iend block.
	
	filesize=$(stat --printf="%s" $temp_file)
	
	LinesForPNGDEBUG=0
	
	until (( LinesForPNGDEBUG == 1 ))
	do
		#echo "NumberofLines:"$LinesForPNGDEBUG
		previousidat=$(( 16#${array[2]} ))

		#echo $(( (16#${array[2]} + 500)))
		#echo $filesize
		#echo $idatasize
		#echo ${#previousidat}
		#echo $previousidat



		#echo ${#previousidat}
		#echo $idatasize
 
		mapfile -t array < <("/media/nick/FrankenNas/Computer/Mycology/Bioactive Alkaloids of Hallucinogenic Mushrooms/orig/png-debugger/a.out" $temp_file)

		#echo ${#idatasize}
		#echo $idatasize

		#echo $(( (16#${array[2]} + 500)))
		#echo $filesize

		#echo $(( 16#${array[2]} ))
		#echo $previousidat

		#echo $(( (16#${array[2]} - $previousidat) - 12 )) 

		if [ ${#idatasize} == 8 ]
		then
			idatasize=$(( (16#${array[2]} - $previousidat) - 12 ))
			#idatasize=$(( 16#${idatasize} ))
			idatasize=$(printf "%08x" $idatasize)
			#echo $idatasize
		else
			idatasize="00002000"
		fi

		filesize=$(stat --printf="%s" $temp_file)
		
		#echo $filesize

		# if (( $(( (16#${array[2]} + 500)))  > $filesize ))
		# then
			# echo $(( (16#${array[2]} + 8000)))
			# echo $filesize"ABORT"
			# exit
		# fi

		#echo ${array[1]}
		
		#"/media/nick/FrankenNas/Computer/Mycology/Bioactive Alkaloids of Hallucinogenic Mushrooms/orig/png-debugger/a.out" $temp_file
		
		#echo ${array[2]}
		#echo $(printf "%08x" $filesize) 
		
		if (( $((16#${array[2]})) > $filesize ))
		then
			LinesForPNGDEBUG=1
		else
			case ${array[1]} in
				IDAT)
					idatstring="${array[3]}$idatasize"$IDAT
					echo $idatstring | xxd -ps -r > $temp2
					dd if=$temp_file bs=1 count=$(( 16#${array[2]} )) status=none > $temp1
					# echo "skip:"$(( 16#${array[2]} ))
					dd if=$temp_file skip=$(( 16#${array[2]} )) bs=1 count=$filesize status=none > $temp3
					cat $temp1 $temp2 $temp3 > $temp_file
					;;
				IHDR)
					#echo $idatasize
					ihdrcrccomputed=${array[3]}
					#echo $(( 16#${array[2]} ))
					#idatstring="${array[3]}$idatasize"$IHDR
					echo $ihdrcrccomputed | xxd -ps -r | dd of=$temp_file bs=1 seek=$(( 16#${array[2]} )) count=8 conv=notrunc status=none
					;;
			esac
			LinesForPNGDEBUG=$("/media/nick/FrankenNas/Computer/Mycology/Bioactive Alkaloids of Hallucinogenic Mushrooms/orig/png-debugger/a.out" $temp_file | wc -l)
			previouspreviousidat=$(( 16#${array[2]} ))
		fi
		


		#echo $(( (16#${array[2]} + 500)))
		#echo $filesize

		#echo $filesize
		#echo $(( (16#${array[2]} + 500)))

		
		
	done

	
	
	filesize=$(stat --printf="%s" $temp_file)
	#echo ${array[2]}
	idatasize=$(( ($filesize - $previousidat + 8 ) - 36 ))
	idatasize=$(printf "%08x" $idatasize)
	#echo $idatasize
	#echo $(( 16#${array[2]} + 4))
	#echo $(( 16#${array[2]} + 16#4 ))
	#echo $(( 16#(${array[2]} + 4) ))
	#hexskip=$(( 16#${array[2]} + 4))
	#hexskip=$(( 16#$hexskip ))
	#echo $hexskip
	echo $idatasize| xxd -ps -r | dd of=$temp_file bs=1 seek=$(( $previousidat + 4)) count=8 conv=notrunc status=none
	
	unset array
	mapfile -t array < <("/media/nick/FrankenNas/Computer/Mycology/Bioactive Alkaloids of Hallucinogenic Mushrooms/orig/png-debugger/a.out" $temp_file)
	
	idatcrccomputed=${array[3]}
	#echo $(( 16#${array[2]} ))
	#idatstring="${array[3]}$idatasize"$IHDR
	echo $idatcrccomputed | xxd -ps -r | dd of=$temp_file bs=1 seek=$(( 16#${array[2]} )) count=8 conv=notrunc status=none
	
	LinesForPNGDEBUG=$("/media/nick/FrankenNas/Computer/Mycology/Bioactive Alkaloids of Hallucinogenic Mushrooms/orig/png-debugger/a.out" $temp_file | wc -l)
	
	if (( LinesForPNGDEBUG == 1 ))
	then
		echo $i".png is completed! No Errors!"
		cat $temp_file > $i.png
	else
		echo "file still not perfect!!! abort!"
		exit
	fi
	
	#echo "echo "$idatasize"| xxd -ps -r | dd of="$1" bs=1 skip="$hexskip" count=4 conv=notrunc
	#cat "$temp_file" > debug" > command
	#echo "Found end"
	rm -rf "$temp_file" "$temp1" "$temp2" "$temp3"
	unset array
	LinesForPNGDEBUG=0
# calculate length, idat hex2 - hex1 address = length - 12
done