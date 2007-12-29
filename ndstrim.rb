#!/usr/bin/env ruby

=begin
This file is part of NDSTrim.

NDSTrim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NDSTrim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with NDSTrim.  If not, see <http://www.gnu.org/licenses/>

----------------------------------------------------------------

Implementation of a 2.5 generation NDS Rom Trimmer
Authors: recover and Azimuth
Excessive documentation

A 1st gen trimmer merely backtraced from the end of the rom looking
for FF or 00 padding and removing it.

A 2nd gen trimmer checks the rom size that's defined in the header
and cuts the rom to that size. This is a much better way of trimming
roms, however, some wifi games have a wifi block which exists after the
rom size in the header and so the wifi block trimmed off with the rest
of the padding.

A 2.5 gen trimmer checks for this wifi block and excludes it
from being trimmed in the case of its existance.
=end

class NDSRom
  attr_reader :file_name, :rom_size, :wifi_block

  def initialize(file)

    @file_name = file

    #First we check the file size, if that is correct we
    #read the rom size in the header. If the rom size in the header is not
    #zero we proceed to reading the wifi block and checking whether or not
    #it is present. The final check before trimming is to check if the rom
    #has already been trimmed.
    check_file_size
    read_rom_size
    read_wifi_block
    check_trimmed
  end

  def check_file_size

    #If the rom size is less that 0x200 the file is the size
    #of the nds rom header, meaning there is no rom data
    if File.size(@file_name) <= 0x200
      raise_error("File too small")
    end
  end

  def read_rom_size

    #seek to 0x80 and read four bytes, this
    #is the location of the rom size in the header
    #rewind back to file start
    @file_name.seek(0x80)
    @rom_size = @file_name.read(4).unpack('I')[0]
    @file_name.rewind

    if @rom_size == 0
      raise_error("Rom Size in Header is zero")
    end
  end

  def read_wifi_block

    #seek to the rom size in the header, read the next 136
    #bytes after this, which is the wifi block
    @file_name.seek(@rom_size)
    @wifi_block = @file_name.read(136)
    @file_name.rewind
    check_wifi_block
  end

  def check_wifi_block

    #The wifi block is 136 bytes long, if it doesn't exist it will be padded like all the
    #data after the rom size in the header. ROMs are usually padded with FF or 00,
    #we check for both these paddings. If the 136 bytes after the rom_size is neither then
    #it must contain a working wifi_block.
    unless @wifi_block == ("\000" * 136) || @wifi_block == ("\377" * 136)
      puts "Wifi block exists"

      #Append wifi block if it exists.
      @rom_size = @rom_size + 136
    else
      return false
    end
  end

  def check_trimmed

    #If the current ROM size is equal to the theoretical ROM
    #size(the rom size in header + wifi block) then the ROM
    #has been (correctly)trimmed before.
    if @rom_size == File.size(@file_name)
      raise_error("Rom has already been trimmed")
    end
  end

  def trim(out_file_name=nil)

    unless @file_name == out_file_name || out_file_name.nil?

      #While the rom's offset is less than the size it should be trimmed to
      #write the number of bytes defined in the buffer from the untrimmed
      #file to the trimmed file. Once the ROM's offset + the buffer is greater
      #than the size it should be the buffer is redefined to be the required rom_size
      #subtracted by the rom offset, which is essentially the bytes left to be written
      #to the new file so that it equals the required size.
      File.open(out_file_name, 'wb') do |rom|
        buffer = 1_000_000
        while rom.pos < @rom_size
          if rom.pos + buffer > @rom_size
            buffer = @rom_size - rom.pos
          end
          rom.write(@file_name.read(buffer))
        end
      end
    else

      #truncates file in place
      @file_name.truncate(@rom_size)
    end
  end

  def raise_error(error)

    #print error to stdout and exit 1
    puts error
    exit 1
  end
end

if __FILE__ == $0

  #Creates a block that passes an open file to
  #the class NDSRom, this way we can avoid
  #re-opening the same file over and over
  File.open(ARGV[0], "r+b") do |file|
    rom = NDSRom.new(file)
    rom.trim(ARGV[1])
  end
end
