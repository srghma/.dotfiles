google-mk-key () {
  keytool \
    -genkeypair \
    -keystore /home/srghma/.dotfiles/secrets/my-release-key.keystore \
    -alias mykey \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Serhii Khoma, OU=Development, O=Serhii Khoma, L=Rodynskoye, ST=Donetsk, C=UA"

}
