require_relative 'spec_helper'

describe RedisioHelper do
  describe '#load_secret' do
    let(:item) do
      {
        'id' => 'the_item',
        'the_key' => 'the_secret'
      }
    end

    context 'chef vault' do
      it 'returns the secret' do
        expect(ChefVault::Item).to receive(:load).with(
          'the_vault',
          'the_item'
        ).and_return(item)

        expect(
          RedisioHelper.load_secret(
            'chef_vault_name' => 'the_vault',
            'chef_vault_item' => 'the_item',
            'chef_vault_key' => 'the_key'
          )
        ).to eq('the_secret')
      end
    end

    context 'chef encrypted data bag item' do
      it 'returns the secret' do
        expect(Chef::EncryptedDataBagItem).to receive(:load_secret).with(
          '/path/to/secret'
        ).and_return(
          'decrypt_key'
        )
        expect(Chef::EncryptedDataBagItem).to receive(:load).with(
          'the_data_bag',
          'the_item',
          'decrypt_key'
        ).and_return(item)

        expect(
          RedisioHelper.load_secret(
            'data_bag_name' => 'the_data_bag',
            'data_bag_item' => 'the_item',
            'data_bag_secret' => '/path/to/secret',
            'data_bag_key' => 'the_key'
          )
        ).to eq('the_secret')
      end
    end
  end
end
