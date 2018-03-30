require_relative 'spec_helper'

describe RedisioHelper do
  describe '#load_secret' do
    context 'bag and item unspecified' do
      it 'returns nil' do
        expect(RedisioHelper.load_secret).to be_nil
      end
    end

    context 'bag and item specified' do
      before do
        allow(ChefVault::Item).to receive(:data_bag_item_type).with(
          bag_name,
          item_name
        ).and_return(item_type)
      end

      let(:bag_name) { 'the_bag' }
      let(:item_name) { 'the_item' }
      let(:password) { 'abc123' }
      let(:item) do
        {
          'id' => 'the_item',
          'password' => password
        }
      end

      context 'chef vault item' do
        let(:item_type) { :vault }

        it 'returns the password' do
          expect(ChefVault::Item).to receive(:load).with(
            bag_name,
            item_name
          ).and_return(item)

          expect(
            RedisioHelper.load_secret(
              'data_bag_name' => bag_name,
              'data_bag_item' => item_name
            )
          ).to eq(password)
        end
      end

      context 'chef encrypted data bag item' do
        let(:item_type) { :encrypted }

        it 'returns the password' do
          expect(Chef::EncryptedDataBagItem).to receive(:load_secret).with(
            '/path/to/secret'
          ).and_return('encrypted_data_bag_secret')

          expect(Chef::EncryptedDataBagItem).to receive(:load).with(
            bag_name,
            item_name,
            'encrypted_data_bag_secret'
          ).and_return(item)

          expect(
            RedisioHelper.load_secret(
              'data_bag_name' => bag_name,
              'data_bag_item' => item_name,
              'data_bag_secret' => '/path/to/secret'
            )
          ).to eq(password)
        end

        # it 'returns the secret' do
        #   expect(Chef::EncryptedDataBagItem).to receive(:load_secret).with(
        #     '/path/to/secret'
        #   ).and_return(
        #     'decrypt_key'
        #   )
        #   expect(Chef::EncryptedDataBagItem).to receive(:load).with(
        #     'the_data_bag',
        #     'the_item',
        #     'decrypt_key'
        #   ).and_return(item)

        #   expect(
        #     RedisioHelper.load_secret(
        #       'data_bag_name' => 'the_data_bag',
        #       'data_bag_item' => 'the_item',
        #       'data_bag_secret' => '/path/to/secret',
        #       'data_bag_key' => 'the_key'
        #     )
        #   ).to eq('the_secret')
        # end
      end

      context 'chef unencrypted data bag item' do
        let(:item_type) { :normal }

        it 'returns the password' do
          expect(Chef::EncryptedDataBagItem).to receive(:load_secret).with(
            '/path/to/secret'
          ).and_return('encrypted_data_bag_secret')

          expect(Chef::EncryptedDataBagItem).to receive(:load).with(
            bag_name,
            item_name,
            'encrypted_data_bag_secret'
          ).and_return(item)

          expect(
            RedisioHelper.load_secret(
              'data_bag_name' => bag_name,
              'data_bag_item' => item_name,
              'data_bag_secret' => '/path/to/secret'
            )
          ).to eq(password)
        end
      end
    end
  end
end
