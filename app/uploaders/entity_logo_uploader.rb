# encoding: utf-8
class EntityLogoUploader < CarrierWave::Uploader::Base
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{Time.now.to_i}"
  end
  
  def extension_white_list
    %w(jpg jpeg gif png)
  end  
end
