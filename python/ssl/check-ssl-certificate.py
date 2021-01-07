import socket
import ssl
import sys


hostname = sys.argv[1]
try:
    ports = sys.argv[2:]
except:
    ports = [443]

if len(ports) == 0:
    ports = [443]


context = ssl.create_default_context()
context.verify_mode = ssl.CERT_REQUIRED
# context.check_hostname = True
context.check_hostname = True


for port in ports:

    with socket.create_connection((hostname, int(port))) as sock:
        try:
            with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                print(ssock.version())
                cert = ssock.getpeercert()
                for key in cert:
                    if key in ("issuer", "subject"):
                        print("{}:".format(key))
                        for k in cert[key]:
                            (e, v) = k[0]
                            if e in ("subjectAltName"):
                                print("    {}:".format(e))
                                for a in v:
                                    (b, c) = a[0]
                                    print("        {}: {}".format(b, c))
                            else:
                                print("    {}: {}".format(e, v))
                    else:
                        print("    {}: {}".format(key, cert[key]))
            print(f"[+] {hostname}:{port} : ok")
        except ssl.SSLCertVerificationError as e:
            print(f"[-] {hostname}:{port} : ko ({e.verify_message})")
