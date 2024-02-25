{
  writeShellApplication,
  dependency,
}:
writeShellApplication {
  name = "dependent";
  runtimeInputs = [dependency];
  text = ''
    echo "This is dependent."
    echo "We will now run dependency."
    dependency
  '';
}
