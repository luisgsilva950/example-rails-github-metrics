# Inicializador para ajustar verificação SSL do Jira quando há CA corporativa ou problemas de cadeia.
# Use as variáveis:
#  JIRA_SSL_CERT_FILE: caminho para um arquivo PEM contendo a CA raiz/intermediária
#  JIRA_SSL_CERT_PATH: diretório com múltiplos PEMs
#  JIRA_VERIFY_SSL: '0' para desativar verificação (apenas dev)
# Este initializer não desativa verificação; isso é controlado no JiraClient.
# Aqui apenas anexamos certificados extras ao store padrão.

require 'openssl'

extra_file = ENV['JIRA_SSL_CERT_FILE']
extra_path = ENV['JIRA_SSL_CERT_PATH']
extra_crl_file = ENV['JIRA_SSL_CRL_FILE']
extra_crl_path = ENV['JIRA_SSL_CRL_PATH']

begin
  if extra_file.present? && File.exist?(extra_file)
    pem = File.read(extra_file)
    certs = pem.scan(/-----BEGIN CERTIFICATE-----(?:.|\n)*?-----END CERTIFICATE-----/)
    if certs.empty?
      Rails.logger.warn "[jira_ssl] Nenhum certificado encontrado em #{extra_file}"
    else
      store = OpenSSL::X509::Store.new
      store.set_default_paths
      certs.each do |c|
        begin
          store.add_cert(OpenSSL::X509::Certificate.new(c))
        rescue OpenSSL::X509::StoreError => e
          Rails.logger.debug "[jira_ssl] Cert não adicionado: #{e.message}"
        end
      end
      Object.const_set(:JIRA_EXTRA_SSL_STORE, store) unless defined?(JIRA_EXTRA_SSL_STORE)
      Rails.logger.info "[jira_ssl] Carregados #{certs.size} certificados de #{extra_file} para uso futuro."
    end
  elsif extra_file.present?
    Rails.logger.warn "[jira_ssl] Arquivo especificado em JIRA_SSL_CERT_FILE não existe: #{extra_file}"
  end

  if extra_path.present? && Dir.exist?(extra_path)
    Rails.logger.info "[jira_ssl] Diretório de certificados adicional definido: #{extra_path}"
  elsif extra_path.present?
    Rails.logger.warn "[jira_ssl] Diretório especificado em JIRA_SSL_CERT_PATH não existe: #{extra_path}"
  end

  if defined?(JIRA_EXTRA_SSL_STORE)
    store = JIRA_EXTRA_SSL_STORE
    if extra_crl_file.present? && File.exist?(extra_crl_file)
      crl_pem = File.read(extra_crl_file)
      crls = crl_pem.scan(/-----BEGIN X509 CRL-----(?:.|\n)*?-----END X509 CRL-----/)
      crls.each do |c|
        begin
          store.add_crl(OpenSSL::X509::CRL.new(c))
        rescue OpenSSL::X509::StoreError => e
          Rails.logger.debug "[jira_ssl] CRL não adicionada: #{e.message}"
        end
      end
      Rails.logger.info "[jira_ssl] Carregadas #{crls.size} CRLs de #{extra_crl_file}."
      store.flags = OpenSSL::X509::V_FLAG_CRL_CHECK | OpenSSL::X509::V_FLAG_CRL_CHECK_ALL if crls.any?
    elsif extra_crl_file.present?
      Rails.logger.warn "[jira_ssl] Arquivo CRL especificado em JIRA_SSL_CRL_FILE não existe: #{extra_crl_file}"
    end

    if extra_crl_path.present? && Dir.exist?(extra_crl_path)
      Dir[File.join(extra_crl_path, '*.crl')].each do |crl_file|
        begin
          crl = OpenSSL::X509::CRL.new(File.read(crl_file))
          store.add_crl(crl)
        rescue StandardError => e
          Rails.logger.debug "[jira_ssl] Falha ao adicionar CRL #{crl_file}: #{e.message}"
        end
      end
      Rails.logger.info "[jira_ssl] Diretório CRL processado: #{extra_crl_path}"
      store.flags = OpenSSL::X509::V_FLAG_CRL_CHECK | OpenSSL::X509::V_FLAG_CRL_CHECK_ALL
    elsif extra_crl_path.present?
      Rails.logger.warn "[jira_ssl] Diretório especificado em JIRA_SSL_CRL_PATH não existe: #{extra_crl_path}"
    end
  end
rescue StandardError => e
  Rails.logger.error "[jira_ssl] Erro ao processar certificados extras: #{e.class}: #{e.message}"
end
