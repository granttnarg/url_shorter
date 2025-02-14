require 'socket'
require 'openssl'
require 'httparty'

class UrlCheckerService

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
  SAFE_BROWSING_API_URL = 'https://safebrowsing.googleapis.com/v4/threatMatches:find'
  UNSAFE_URL_FOR_TESTING = "http://malware.testing.google.test/testing/malware/"

  def initialize
    @api_key = Rails.configuration.x.google_safe_browsing_api_key
  end

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

  def check_url_safelist(url = nil)
    body = JSON.generate(payload(url))
    headers = { 'Content-Type' => 'application/json' }
    response = HTTParty.post("#{SAFE_BROWSING_API_URL}?key=#{@api_key}", body:, headers:)

    response["matches"].nil?
  end

  private

  def payload(url)
      {
    "client": {
      "clientId": "url-test-app",
      "clientVersion": "1.0"
    },
    "threatInfo": {
      "threatTypes": [
        "MALWARE",
        "SOCIAL_ENGINEERING",
        "UNWANTED_SOFTWARE",
        "POTENTIALLY_HARMFUL_APPLICATION"
      ],
      "platformTypes": ["ANY_PLATFORM"],
      "threatEntryTypes": ["URL"],
      "threatEntries": [
        {"url": url || UrlCheckerService::UNSAFE_URL_FOR_TESTING }
      ]
    }
  }
  end

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