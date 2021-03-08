class String
  def as_win_path
    tr('/', '\\')
  end

  # colorization only works with shells that support ansii escape colors
  # conemu does this or you can use ansicon (https://github.com/adoxa/ansicon) to wrap
  # console/powershell
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end
end
