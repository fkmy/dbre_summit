# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RedundantSchemaIndex, :config do
  include RuboCop::RSpec::ExpectOffense

  context 'when no duplicate columns in index' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        create_table "tbl" do |t|
          t.integer "col1", null: false
          t.string "col2", null: false
          t.datetime "col3", null: false
          t.index ["col3"], name: "idx1"
          t.index ["col2", "col3"], name: "idx2"
          t.index ["col2", "col1"], name: "idx3"
          t.index ["col1", "col2", "col3"], name: "idx4"
        end
      RUBY
    end
  end

  context 'when duplicate columns in index' do
    it 'registers offense' do
      expect_offense(<<~RUBY)
        create_table "tbl" do |t|
          t.integer "col1", null: false
          t.string "col2", null: false
          t.datetime "col3", null: false
          t.index ["col1"], name: "idx1"
                   ^^^^^^ Unnecessary index since a index with the same combination until partway is available.
          t.index ["col1", "col2"], name: "idx2", unique: false
                           ^^^^^^ Unnecessary index since a index with the same combination until partway is available.
                   ^^^^^^ Unnecessary index since a index with the same combination until partway is available.
          t.index ["col1", "col2", "col3"], name: "idx3"
        end
      RUBY
    end

    context 'when mixed symbol type' do
      it 'registers offense' do
        expect_offense(<<~RUBY)
          create_table "tbl" do |t|
            t.integer "col1", null: false
            t.string "col2", null: false
            t.datetime "col3", null: false
            t.index :col1, name: "idx1"
                    ^^^^^ Unnecessary index since a index with the same combination until partway is available.
            t.index [:col1, :col2], name: "idx2"
                            ^^^^^ Unnecessary index since a index with the same combination until partway is available.
                     ^^^^^ Unnecessary index since a index with the same combination until partway is available.
            t.index ["col1", "col2", "col3"], name: "idx3"
          end
        RUBY
      end
    end

    context 'when mixed unique index' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          create_table "tbl" do |t|
            t.integer "col1", null: false
            t.string "col2", null: false
            t.datetime "col3", null: false
            t.index ["col1"], name: "idx1", unique: true
            t.index ["col1", "col2"], name: "idx2"
          end
        RUBY
      end
    end
  end
end
