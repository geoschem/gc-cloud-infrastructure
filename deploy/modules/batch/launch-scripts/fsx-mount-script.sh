MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==BOUNDARY=="

--==BOUNDARY==
Content-Type: text/cloud-config; charset="us-ascii"

runcmd:
- amazon-linux-extras install -y lustre2.10
- mkdir -p ${input_data_path}
- mount -t lustre -o noatime,flock ${fsx_address}@tcp:/fsx ${input_data_path}

--==BOUNDARY==--