require 'socket'
require 'openssl'

class SslCheckerService

  TRUSTED_ISSUERS = [
    "DigiCert",
    "Let's Encrypt",
    "GlobalSign",
    "Sectigo",
    "Entrust",
    "GoDaddy",
    "Google Trust Services",
    "Amazon",
    "Microsoft",
    "Cloudflare",
    "Buypass",
    "SSL.com",
    "Trustwave",
    "GeoTrust",
    "Thawte",
    "Comodo",
    "RapidSSL",
    "Actalis",
    "IdenTrust",
    "Secom Trust",
    "Cybertrust"
  ]

  TRUSTED_ALGORITHMS = [
    "sha256WithRSAEncryption",
    "sha384WithRSAEncryption",
    "sha512WithRSAEncryption",
    "ecdsa-with-SHA256",
    "ecdsa-with-SHA384",
    "ecdsa-with-SHA512",
    "Ed25519",
    "Ed448"
  ]

  ## MIGHT BE WORTH ADDING THIS TOO?

  # def safe_url?
  #   uri = URI.parse(original)
  #   response = HTTP.get("https://safebrowsing.googleapis.com/v4/threatMatches:find",
  #     params: { key: GOOGLE_API_KEY },
  #     json: { threatInfo: { ... } }
  #   )
  #   response["matches"].empty?
  # end

  def self.check_ssl(domain, port = 443)
    init_result = ssl_initialize(domain, port)
    init_result.ssl.connect

    cert = init_result.ssl.peer_cert
    init_result.ssl.close
    init_result.socket.close

    {
      valid?: valid_ssl?(cert),
      issuer: cert.issuer.to_s,
      subject: cert.subject.to_s,
      valid_from: cert.not_before,
      valid_to: cert.not_after,
      serial: cert.serial.to_s,
      algorithm: cert.signature_algorithm
    }
  rescue OpenSSL::SSL::SSLError, OpenSSL::X509::CertificateError
    { valid?: false, error: 'certificate_error' }
  rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT
    { valid?: false, error: 'connection_error' }
  end

  private

  def self.ssl_initialize(domain, port)
    ctx = OpenSSL::SSL::SSLContext.new
    socket = TCPSocket.new(domain, port)
    ssl = OpenSSL::SSL::SSLSocket.new(socket, ctx)
    ssl.hostname = domain
    OpenStruct.new(socket: socket, ssl: ssl)
  end

  def self.valid_ssl?(cert)
    certificate_valid?(cert.not_after) && trusted_algorithm?(cert.signature_algorithm) && trusted_issuer?(cert.issuer.to_s)
  end

  def self.certificate_valid?(certificate_time)
    certificate_time > Time.now
  end

  def self.trusted_algorithm?(algorthm_type)
    TRUSTED_ALGORITHMS.include?(algorthm_type)
  end

  def self.trusted_issuer?(issuer_string)
    match = issuer_string.match((/\/O=([^\/]+)/))
    match ? TRUSTED_ISSUERS.include?(match[1]) : false
  end
end