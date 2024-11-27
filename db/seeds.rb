# Access Levels
access_levels = [
  { name: 'Read', description: 'Can view but not modify' },
  { name: 'Write', description: 'Can create and edit' },
  { name: 'Admin', description: 'Full access including system settings' },
  { name: 'Super Admin', description: 'Unrestricted access to all features' }
]

access_levels.each do |level|
  AccessLevel.find_or_create_by!(name: level[:name]) do |al|
    al.description = level[:description]
  end
end

# Categories
categories = [
  { name: 'User Management', description: 'Permissions related to user accounts and profiles' },
  { name: 'Content Management', description: 'Permissions for creating, editing, and deleting content' },
  { name: 'System Settings', description: 'Permissions for configuring system-wide settings' },
  { name: 'Reporting', description: 'Permissions for accessing and generating reports' },
  { name: 'API Access', description: 'Permissions for using API endpoints' }
]

categories.each do |category|
  Category.find_or_create_by!(name: category[:name]) do |cat|
    cat.description = category[:description]
  end
end

# Roles
roles = [
  { name: 'Guest', hierarchy_level: 0 },
  { name: 'User', hierarchy_level: 1 },
  { name: 'Moderator', hierarchy_level: 2 },
  { name: 'Admin', hierarchy_level: 3 },
  { name: 'Super Admin', hierarchy_level: 4 }
]

roles.each do |role|
  Role.find_or_create_by!(name: role[:name]) do |r|
    r.hierarchy_level = role[:hierarchy_level]
  end
end

# Permissions
permissions = [
  { name: 'view_profile', access_level: 'Read', category: 'User Management' },
  { name: 'edit_profile', access_level: 'Write', category: 'User Management' },
  { name: 'create_content', access_level: 'Write', category: 'Content Management' },
  { name: 'delete_content', access_level: 'Admin', category: 'Content Management' },
  { name: 'view_reports', access_level: 'Read', category: 'Reporting' },
  { name: 'manage_users', access_level: 'Admin', category: 'User Management' },
  { name: 'configure_system', access_level: 'Super Admin', category: 'System Settings' }
]

permissions.each do |permission|
  Permission.find_or_create_by!(name: permission[:name]) do |p|
    p.access_level = AccessLevel.find_by(name: permission[:access_level])
    p.category = Category.find_by(name: permission[:category])
    p.scope = 'global'
  end
end

# Create a Super Admin User
super_admin = User.find_or_create_by!(email: 'roblineyegon@gmail.com') do |user|
  user.f_name = 'Robline'
  user.l_name = 'Yegon'
  user.status = 'active'
  user.otp_enabled = false
  user.password = 'password'
  user.password_confirmation = 'password'
  user.confirmed_at = Time.now
 end

 # Assign Role to Super Admin User
 admin_role = Role.find_by(name: 'Super Admin')
 super_admin.roles << admin_role unless super_admin.roles.include?(admin_role)
