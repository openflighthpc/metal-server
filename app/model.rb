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
  include FlightConfig::Deleter

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

    def type
      raise NotImplementedError
    end

    def user_roles
      Service.enabled?(type) ? [:user, :admin] : [:forbidden]
    end

    def admin_roles
      Service.enabled?(type) ? [:admin] : [:forbidden]
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
  class << self
    def inherited(subclass)
      FileModel.inherited_classes << subclass
    end

    def abstract_class
      FileModel.inherited_classes.delete(self)
    end

    def inherited_classes
      @inherited_classes ||= []
    end

    # This is used by the serializer to define the type
    def type
      raise NotImplementedError
    end
  end

  def filename
    raise NotImplementedError
  end

  def system_path
    raise NotImplementedError
  end

  def uploaded?
    File.exists? system_path
  end

  def size
    return 0 unless uploaded?
    File.size system_path
  end

  def payload
    uploaded? ? File.read(system_path) : ''
  end
end

module HasSingleInput
  extend ActiveSupport::Concern

  class_methods do
    def path(id)
      File.join(content_base_path, 'meta', type, id + '.yaml')
    end
  end

  def id
    __inputs__[0]
  end
end

class SingleIDFileModel < FileModel
  abstract_class
  include HasSingleInput
end

