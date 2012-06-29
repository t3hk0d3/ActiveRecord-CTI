module ActiveRecord
	module ClassTableInheritance
		extend ActiveSupport::Concern

		module ClassMethods
			def class_table_inheritance
				self.send(:include, ActiveRecord::ClassTableInheritance::Implementation)
			end
		end

		module Persistence
			def update
				raise Error.new
			end

			def create
				raise Error.new
				@new_record = false
			end
		end

		module Implementation
			def self.included(base)
				base.extend(ClassMethods)
			end

			module ClassMethods
				def self.extended(base)
					base.setup_inheritance
				end

				def setup_inheritance
					@parent_models = []
					@models_map = {}

					klass = self.superclass
					until klass == ActiveRecord::Base
						# Save only real models, not STI models
						if klass.base_class == klass || klass.base_class.table_name != klass.table_name
							@parent_models << klass
							@models_map[klass.table_name] = klass
						end

						klass = klass.superclass
					end

					self.primary_key = compute_foreign_key
					# self.primary_key = "#{self.base_class.table_name}.#{self.base_class.primary_key}"
				end

				def parent_models
					@parent_models
				end

				def compute_foreign_key
					"#{self.base_class.to_s.underscore.singularize}_#{self.base_class.primary_key}"
				end

				def columns
					unless defined? @columns_map
						@columns_map = {}
						@parent_models.each do |parent|
							@columns_map[parent.table_name] = parent.columns
						end

						@columns_map[table_name] = super
						@columns = @columns_map.values.flatten.uniq
					end

					super
				end

				def compute_table_name
					if parent < ActiveRecord::Base && !parent.abstract_class?
						contained = parent.table_name
						contained = contained.singularize if parent.pluralize_table_names
						contained += '_'
					end

					"#{full_table_name_prefix}#{contained}#{undecorated_table_name(name)}#{table_name_suffix}"
				end


				def fields_map
					unless defined? @fields_map
						# Call to create columns map
						columns unless defined? @columns_map

						@fields_map = {}

						@columns_map.map do |table, columns|
							columns.each { |column| @fields_map[column.name.to_s.underscore] = table }
						end
					end

					@fields_map
				end

				def delete(id)
					super

					@parent_models.each { |parent| parent.delete(id) }
				end

				def cti_insert(attributes)
					class_attrs = _split_attributes(attributes)

					parent_primary_key = nil

					# Insert parents data starting base class (to obtain primary key)
					([self] + @parent_models).reverse.each do |parent|
						# no data for this parent table
						next unless class_attrs.include? parent.table_name

						data = class_attrs[parent.table_name]

						# Inject primary key
						data[parent.arel_table[parent.primary_key]] = parent_primary_key unless parent_primary_key.nil?

						key = parent.unscoped.insert data

						# Extract primary key
						parent_primary_key = key if parent == self.base_class
					end

					parent_primary_key
				end

				def cti_update(id, attributes)
					return 0 if attributes.empty?

					class_attrs = _split_attributes(attributes)
					([self] + @parent_models).reverse.each do |parent|
						unless class_attrs.include? parent.table_name # no data for this parent table
							next
						end

						parent.connection.update parent.unscoped.where(parent.arel_table[parent.primary_key].eq(id)).arel.compile_update(class_attrs[parent.table_name])
					end
				end

				protected

				def _split_attributes(attributes)
					class_attrs = {}

					attributes.map do |attr, value|
						table = fields_map[attr.name]

						class_attrs[table] = {} if class_attrs[table].nil?

						if @models_map.include? table # Fix attribute table
							attr.relation = @models_map[table].arel_table
						end

						class_attrs[table][attr] = value
					end

					return class_attrs
				end

				def expand_hash_conditions_for_aggregates(opts)
					unless defined? @columns_map
						return super opts
					end

					fixed_opts = {}
					map = fields_map

					opts.map do |key, value|
						key = key.to_s

						if !key.include?(".") and map.key? key.underscore
							key = "#{fields_map[key.underscore]}.#{key}"
						end

						fixed_opts[key] = value
					end

					super fixed_opts
				end

				private
				def relation
					relation = super

					relation = relation.select(self.arel_table[Arel.star])

					@parent_models.each do |model|
						foreign_table = model.arel_table

						relation = relation.joins(
							foreign_table.create_join(foreign_table,
							                          foreign_table.create_on(foreign_table[model.primary_key].eq(self.arel_table[primary_key]))
							)
						)

						relation = relation.select(foreign_table[Arel.star])
					end

					relation
				end
			end
		end
	end
end

module ActiveRecord::Persistence

	alias_method :_create_, :create
	alias_method :_update_, :update
	alias_method :_destroy_, :destroy

	def create
		return _create_ unless self.class.include? ActiveRecord::ClassTableInheritance::Implementation

		self.id ||= self.class.cti_insert(arel_attributes_values(!id.nil?))

		ActiveRecord::IdentityMap.add(self) if ActiveRecord::IdentityMap.enabled?
		@new_record = false
		id
	end

	def update(attribute_names = @attributes.keys)
		return _update_(attribute_names) unless self.class.include? ActiveRecord::ClassTableInheritance::Implementation

		self.class.cti_update(id, arel_attributes_values(false, false, attribute_names))
	end

	def destroy
		if self.class.include? ActiveRecord::ClassTableInheritance::Implementation
			self.class.parent_models.each do |parent|
				pk = parent.primary_key
				column = parent.columns_hash[pk]
				substitute = parent.connection.substitute_at(column, 0)

				relation = parent.unscoped.where(
					parent.arel_table[pk].eq(substitute))

				relation.bind_values = [[column, id]]
				relation.delete_all
			end
		end

		_destroy_
	end
end

class ActiveRecord::Base
	include ActiveRecord::ClassTableInheritance
end