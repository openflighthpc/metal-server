# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Metal Server.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Metal Server is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cloud. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Metal Server, please visit:
# https://github.com/openflighthpc/metal-server
#===============================================================================

class Model
  include FlightConfig::Reader
  include FlightConfig::Updater
  include FlightConfig::Globber

  class << self
    attr_writer :content_base_path

    def content_base_path
      Model.instance_variable_get(:@content_base_path) || raise(<<~ERROR.chomp)
        The base content path for the models has not been set!
      ERROR
    end

    def exists?(*a)
      File.exists? path(*a)
    end
  end

  def id
    raise NotImplementedError
  end
end

# TODO: Eventually make this a complete replacement to FileModel
# All files need to follow this same pattern. However it will be
# phased-in in stages

class FileModel < Model
  module SingleIDInput
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def path(id)
        File.join(content_base_path, type, id + '.yaml')
      end

      private

      def input_arity
        1
      end
    end

    def id
      __inputs__[0]
    end
  end

  class << self
    attr_writer :base_url, :base_path

    def inherited(subclass)
      FileModel.inherited_classes << subclass
    end

    def abstract_class
      FileModel.inherited_classes.delete(self)
    end

    def inherited_classes
      @inherited_classes ||= []
    end

    def base_path
      if self == FileModel && !@base_path
        raise "The base path has not been set"
      elsif @base_path
        @base_path
      else
        File.join(FileModel.base_path, type)
      end
    end

    def base_url
      if self == FileModel && !@base_url
        raise "The base url has not been set"
      elsif @base_url
        @base_url
      else
        File.join(FileModel.base_url, type)
      end
    end

    # This is used by the serializer to define the type
    def type
      raise NotImplementedError
    end

    def find_from_filename(filename)
      return nil unless filename_regex.match?(filename)
      matches = filename_regex.match(filename)
      inputs = input_keys.map { |k| matches[k] }
      exists?(*inputs) ? read(*inputs) : nil
    end

    def perl_match_all_filename
      @perl_match_all_filename ||= new(*(0...input_arity).map { '.*' }).filename
    end

    private

    def filename_regex
      @filename_regex ||= begin
        parts = input_keys.map { |k| "(?<#{k}>.*)" }
        /\A#{new(*parts).filename}\Z/
      end
    end

    def input_keys
      @input_keys ||= (0...input_arity).map { |i| "arg#{i}" }
    end

    def input_arity
      raise NotImplementedError
    end
  end

  # The name of the object is equivalent to its ID
  def name
    id
  end

  def filename
    raise NotImplementedError
  end

  def system_path
    File.join(self.class.base_path, filename)
  end

  def download_url
    File.join(self.class.base_url, filename)
  end

  def uploaded?
    File.exists? system_path
  end

  def size
    return 0 unless uploaded?
    File.size system_path
  end
end

class SingleIDFileModel < FileModel
  abstract_class

  include SingleIDInput
end

