defmodule Roomy.Crypto do
  # 12 bytes (96 bits) is recommended for AES-GCM IV
  @iv_length 12

  def generate_key_pair() do
    :crypto.generate_key(:ecdh, :secp256r1)
  end

  def generate_shared_secret(private_key, other_public_key) do
    :crypto.compute_key(:ecdh, other_public_key, private_key, :secp256r1)
  end

  def derive_aes_key(shared_secret) do
    :crypto.hash(:sha256, shared_secret)
  end

  def encrypt_message(message, aes_key) do
    iv = :crypto.strong_rand_bytes(@iv_length)

    {encrypted_message, tag} =
      :crypto.crypto_one_time_aead(:aes_gcm, aes_key, iv, message, "", true)

    {iv, encrypted_message, tag}
  end

  def decrypt_message({iv, encrypted_message, tag}, aes_key) do
    :crypto.crypto_one_time_aead(:aes_gcm, aes_key, iv, encrypted_message, "", tag, false)
  end
end
