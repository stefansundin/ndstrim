module Trimmer

  def trim_nds(file)
    if system("#@ndstrim #{file} #{@target_path + '/' + File.basename(file)}")
      puts "\e[32m#{file} trimmed successfully\e[0m"
      file_delete(file)
    else
      error_file(file)
    end
  end

  def file_delete(file)
    unless @config["keep_original"]
      File.delete(file)
    end
  end

  def error_file(file)
    if @config["error_files"]
      File.open(@target_path + "error_ndstrim." + File.basename(file), "w") {puts "\e[33Trimming Failed:Error file output to target directory\e[0m"}
    else
      puts "\e[33mTrimming failed!\e[0m"
    end
  end

  def unrar(file)
    if system("unrar x -inul #{file} #@path")
      puts "#{file} unrared successfully"
      file_delete(file)
    else
      puts "\e[33mUnraring failed!\e[0m"
    end
  end

  def unzip(file)
    if system("unzip -qq #{file} -d #@path")
      puts "#{file} unziped successfully"
      file_delete(file)
      else
      puts "\e[33mUnzipping failed!\e[0m"
    end
  end

  def sevenz(file)
    if system("7z x -bd -y -o#@path #{file}")
      puts "#{file} extracted successfully"
      file_delete
    else
      puts "\e[33mExtraction failed\e[0m"
    end
  end

  def untar(file)
    if system("tar -xf #{file} --no-ignore-command-error -C #@path")
      puts "#{file} untarred successfully"
      file_delete
      else
      puts "\e[33mUntarring Failed\e[0m"
    end
  end

end
