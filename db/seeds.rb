# db/seeds.rb

# 1. Access Levels
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

puts "Access levels seeded."

# 2. Categories
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

puts "Categories seeded."

# 3. Roles
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

puts "Roles seeded."

# 4. Permissions
permissions = [
  { name: 'view_profile', access_level: 'Read', category: 'User Management' },
  { name: 'edit_profile', access_level: 'Write', category: 'User Management' },
  { name: 'create_content', access_level: 'Write', category: 'Content Management' },
  { name: 'delete_content', access_level: 'Admin', category: 'Content Management' },
  { name: 'view_reports', access_level: 'Read', category: 'Reporting' },
  { name: 'configure_system', access_level: 'Super Admin', category: 'System Settings' },
  { name: 'detach_permissions', access_level: 'Admin', category: 'User Management' },
  { name: 'add_users', access_level: 'Admin', category: 'User Management' },
  { name: 'remove_users', access_level: 'Admin', category: 'User Management' },
  { name: 'add_permissions', access_level: 'Admin', category: 'User Management' },
  { name: 'remove_permissions', access_level: 'Admin', category: 'User Management' },
  { name: 'create_comment', access_level: 'Write', category: 'Content Management' },
  { name: 'update_comment', access_level: 'Write', category: 'Content Management' },
  { name: 'show_comment', access_level: 'Read', category: 'Content Management' },
  { name: 'destroy_comment', access_level: 'Admin', category: 'Content Management' },
  { name: 'manage_users', access_level: 'Admin', category: 'User Management' },
  { name: 'create draft', access_level: 'Write', category: 'Content Management' },
  { name: 'list drafts', access_level: 'Read', category: 'Content Management' },
  { name: 'read draft', access_level: 'Read', category: 'Content Management' },
  { name: 'update draft', access_level: 'Write', category: 'Content Management' },
  { name: 'delete draft', access_level: 'Admin', category: 'Content Management' },
  { name: 'approve draft', access_level: 'Admin', category: 'Content Management' },
  { name: 'reject draft', access_level: 'Admin', category: 'Content Management' },
  { name: 'review draft', access_level: 'Write', category: 'Content Management' },
  { name: 'manage_permissions', access_level: 'Admin', category: 'User Management' }
]

permissions.each do |permission|
  Permission.find_or_create_by!(name: permission[:name]) do |p|
    p.access_level = AccessLevel.find_by(name: permission[:access_level])
    p.category = Category.find_by(name: permission[:category])
    p.scope = 'global'
  end
end

puts "Permissions seeded."

# 5. Assign All Permissions to Super Admin Role
super_admin_role = Role.find_by(name: 'Super Admin')
if super_admin_role
  all_permission_ids = Permission.pluck(:id)
  super_admin_role.permission_ids = all_permission_ids
  puts "Assigned all permissions to the Super Admin role."
else
  puts "Super Admin role not found. Please ensure the role exists."
end

# 6. Create a Super Admin User
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
if admin_role
  unless super_admin.roles.include?(admin_role)
    super_admin.roles << admin_role
    puts "Assigned Super Admin role to user #{super_admin.email}."
  else
    puts "User #{super_admin.email} already has the Super Admin role."
  end
else
  puts "Super Admin role not found. Please ensure the role exists."
end
