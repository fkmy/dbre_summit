# frozen_string_literal: true

module RuboCop
  module Cop
    # If there is an index with the same combination until partway, that index is unnecessary.
    #
    # Set the files you want cop to inspect to rubocop.yml in `Include`.
    # For example, db/schema.rb if you're using migrate, or db/*.schema if you're using ridgepole.
    #
    # @example
    #   # bad
    #   create_table "tbl" do |t|
    #     t.integer "col1", null: false
    #     t.integer "col2", null: false
    #     t.index ["col1"], name: "idx1"
    #     t.index ["col1", "col2"], name: "idx2"
    #   end
    #
    #   #good
    #   create_table "tbl" do |t|
    #     t.integer "col1", null: false
    #     t.integer "col2", null: false
    #     t.index ["col1", "col2"], name: "idx1"
    #   end

    class RedundantSchemaIndex < ::RuboCop::Cop::Base
      MSG = 'Unnecessary index since a index with the same combination until partway is available.'

      RESTRICT_ON_SEND = %i[index].freeze

      # @param node [RuboCop::AST::SendNode]
      # @return [void]
      def on_send(node)
        create_table_body(node).each_child_node(:send) do |child|
          next if !child.method?(:index) || same_line?(node, child) || unique_index?(node)

          unnecessary_indexes(arguments(node), arguments(child)).each do |idx|
            add_offense(idx)
          end
        end
      end

      private

      def create_table_body(node)
        node.each_ancestor(:block).find { |n| create_table?(n) }.body
      end

      def unnecessary_indexes(node_args, child_args)
        return [] if node_args.length > child_args.length

        target_args = node_args.zip(child_args)
                               .filter_map { |n, c| n if n.value.to_s == c.value.to_s }
        target_args == node_args ? target_args : []
      end

      def arguments(node)
        arg = index_arguments(node)
        arg.array_type? ? arg.child_nodes : [arg]
      end

      # @!method unique_index?(node)
      #   @param node [RuboCop::AST::SendNode]
      #   @return [Boolean]
      def_node_matcher :unique_index?, <<~PATTERN
        (send _ :index ...
          (hash < (pair (sym :unique) true ) ...> )
        )
      PATTERN

      # @!method create_table?(node)
      #   @param node [RuboCop::AST::BlockNode]
      #   @return [Boolean]
      def_node_matcher :create_table?, <<~PATTERN
        (block (send _ :create_table ...) ...)
      PATTERN

      # @!method index_arguments(node)
      #   @param node [RuboCop::AST::SendNode]
      #   @return [Array]
      def_node_matcher :index_arguments, <<~PATTERN
        (send _ :index $({sym array} ...) ...)
      PATTERN
    end
  end
end
