ActiveRecord::Schema.define(:version => 0) do
	create_table :people, :force => true do |t|
		t.string :first_name
		t.string :sur_name
		t.string :last_name
		t.string :type
	end

	create_table :users, :id => false, :force => true do |t|
		t.integer :person_id
		t.string :login
		t.string :email
	end

	create_table :admins, :id => false, :force => true do |t|
			t.integer :person_id
			t.string :permission
		end

end