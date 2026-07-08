return {
  name = "CfxLua Support",
  version = "1.0.0",
  onSetText = function(uri, text)
    return text
      :gsub("%?%.", ".")
      :gsub("%?%[", "[")
      :gsub("%s*%+=", " = ")
      :gsub("%s*%-=", " = ")
      :gsub("%s*%*=", " = ")
      :gsub("%s*/=", " = ")
  end
}
