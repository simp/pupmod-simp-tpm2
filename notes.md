
```bash
yum install -y createrepo
cd /root/rpms.*
createrepo .

# provides xxd
yum install -y vim-common
```


### tpm2_activatecredential test

Create an EK and AK

From https://github.com/tpm2-software/tpm2-tools/blob/3.X/test/system/test_tpm2_activecredential.sh:

```bash
echo "12345678" > secret.data

# -Q, --quiet: Silence normal tool output to stdout.
# -H, --handle=HANDLE: specifies the handle used to make EK persistent (hex).
# -g,  --alg=ALGORITHM:  specifies the algorithm type of EK.  See section
#      "Supported Public Object Algorithms" for a list of supported object algorithms.
#      See section "Algorithm Specifiers" on how to specify an algorithm argument.
#  -f, --file=FILE: specifies the file used to save the public portion of EK.  This will be a binary data structure corre‐
#      sponding to the TPM2B_PUBLIC struct in the specification.
tpm2_getpubek -Q -H 0x81010009 -g rsa -f ek.pub


# -E, --ek-handle=EK_HANDLE: Specifies the handle used to make EK persistent.
# -k, --ak-handle=AK_HANDLE: Specifies the handle used to make AK persistent.
# -g,  --alg=ALGORITHM:  Like  -g,  but  specifies the algorithm of sign.  See
#      section "Supported Signing Algorithms" for details.
# -D  no description
# -s  no description
# -f, --file=FILE: Specifies the file used to save the public portion of AK.
#     This will be a binary data structure corre‐ sponding to the TPM2B_PUBLIC
#     struct in the specification.
tpm2_getpubak -E 0x81010009 -k 0x8101000a -g rsa -D sha256 -s rsassa -f ak.pub -n ak.name > ak.out



loaded_key_name=$(/opt/puppetlabs/puppet/bin/ruby -r yaml -e "puts YAML.load(ARGF)['loaded-key']['name'].scan(/../).join" ak.out)

# -e, --enckey=PUBLIC_FILE: A tpm Public Key which was used to wrap the seed.
# -s, --sec=SECRET_DATA_FILE: The secret which will be protected by the key derived from the random seed.
# -n, --name=NAME The name of the key for which certificate is to be created.
# -o, --out-file=OUT_FILE The output file path, recording the two structures output by tpm2_makecredential function.
tpm2_makecredential -e ek.pub -s secret.data -n "${loadedkey_name}" -o mkcred.out

# -H, --handle=HANDLE: HANDLE of the object associated with the created certificate by CA.
# -k, --key-handle=KEY_HANDLE: The KEY_HANDLE of Loaded key used to decrypt the the random seed.
# -f, --in-file=INPUT_FILE: Input file path, containing the two structures
#     needed  by  tpm2_activatecredential  function. This is created via the
#     tpm2_makecredential(1) command.
# -o, --out-file=OUTPUT_FILE: Output file path, record the secret to decrypt the certificate.
tpm2_activatecredential -Q -H 0x8101000a -k 0x81010009 -f mkcred.out -o actcred.out

# FYI: binary version of the above command (ruby version of `xxd -r -p`)
#/opt/puppetlabs/puppet/bin/ruby -r yaml -e "n=YAML.load(ARGF)['loaded-key']['name'].scan(/../).map(&:hex).pack('C*'); open('lkn.bin','w'){|f| f.puts n }" ak.out
```

#### ruby

```ruby

```
