module PermissionJSON
  def as_json(**options)
    hash = super(**options)
    if (user = options[:user])
      hash.merge!('permissions' => permissions.find_by(user_id: user.id).as_json)
    end
    hash
  end
end
