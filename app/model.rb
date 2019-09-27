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

  def self.exists?(*a)
    File.exists? path(*a)
  end

  def id
    raise NotImplementedError
  end
end

class FileModel < Model
  def system_path
    raise NotImplementedError
  end

  # alias and alias_method are not being used as they do not play
  # well with inheritance. Also I can never remember the difference
  # between the two
  def name
    id
  end

  def uploaded?
    File.exists?(system_path)
  end

  def size
    return 0 unless uploaded?
    File.size system_path
  end
end

