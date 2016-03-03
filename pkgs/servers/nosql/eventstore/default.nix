{ stdenv, fetchFromGitHub, fetchpatch, git, mono, v8, icu, subversion, python, which, cacert}:

# There are some similarities with the pinta derivation. We should
# have a helper to make it easy to package these Mono apps.

stdenv.mkDerivation rec {
  name = "EventStore-${version}";
  version = "3.5.1";
  src = fetchFromGitHub {
    owner  = "nrolland";
    repo   = "EventStore-1";
    rev    = "oss-v${version}";
    sha256 = "0kcvaz8ghmmv9adfv59kkj3aniqf092dr006s8kfq9wj9bgn9z2k";
  };
  
  patches = [
    # see: https://github.com/EventStore/EventStore/issues/461
    #(fetchpatch {
    #  url = https://github.com/EventStore/EventStore/commit/9a0987f19935178df143a3cf876becaa1b11ffae.patch;
    #  sha256 = "04qw0rb1pypa8dqvj94j2mwkc1y6b40zrpkn1d3zfci3k8cam79y";
    #})
  ];


  #for ssl snafu, cf explanation in https://github.com/NixOS/nixpkgs/issues/8247
  buildPhase = ''
    ln -s ${v8}/lib/libv8.so src/libs/libv8.so
    ln -s ${icu}/lib/libicui18n.so src/libs/libicui18n.so
    ln -s ${icu}/lib/libicuuc.so src/libs/libicuuc.so

    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt 
    patchShebangs ./scripts/build-js1/build-js1-linux.sh

    ./scripts/build-js1/build-js1-linux.sh werror=no
    ./build.sh ${version}
  '';

  installPhase = ''
    mkdir -p $out/{bin,lib/eventstore/clusternode}
    cp -r bin/clusternode/* $out/lib/eventstore/clusternode/
    cat > $out/bin/clusternode << EOF
    #!/bin/sh
    exec ${mono}/bin/mono $out/lib/eventstore/clusternode/EventStore.ClusterNode.exe "\$@"
    EOF
    chmod +x $out/bin/clusternode
  '';

  buildInputs = [ git v8 mono subversion python which cacert ];

  dontStrip = true;

  meta = {
    homepage = https://geteventstore.com/;
    description = "Event sourcing database with processing logic in JavaScript";
    license = stdenv.lib.licenses.bsd3;
    maintainers = with stdenv.lib.maintainers; [ puffnfresh ];
    platforms = with stdenv.lib.platforms; linux;
  };
}
