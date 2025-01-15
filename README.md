# Creazione dell'immagine minimal ISO

- Scaricare l'immagine ISO dal sito: [Rocky Linux Download](https://rockylinux.org/download)
- Fare la build del container file con il seguente comando:
   ```sh
   buildah build -t ns8-boxbuilder .
   ```
- Creare il container che modifica l'ISO minimal di Rocky Linux con il seguente comando:
   ```sh
   podman run --rm -it --privileged -v $(pwd):/root localhost/ns8-boxbuilder mkksiso --cmdline "inst.ks=https://raw.githubusercontent.com/tommaso-ascani/rocky-ns8/refs/heads/main/ks.cfg" <nome_immagine_scaricata>.iso ns8.iso
   ```
   > **Nota:** Sostituire `<nome_immagine_scaricata>` con il nome dell'immagine ISO scaricata.
