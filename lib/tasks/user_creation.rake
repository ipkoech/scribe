# lib/tasks/user_creation.rake

namespace :users do
    desc "Create multiple users with specified emails and passwords"
    task create_multiple: :environment do
      users_data = [
        {
          email: 'ania.dagostino@instant-impact.com',
          f_name: 'Ania',
          l_name: 'Dagostino',
          password: 'AniaScribe.ii'
        },
        {
          email: 'iz.flieh@instant-impact.com',
          f_name: 'Iz',
          l_name: 'Flieh',
          password: 'Iz.iiScribe'
        },
        {
          email: 'carla.d.perez@instant-impact.com',
          f_name: 'Carla',
          l_name: 'D. Perez',
          password: 'Perez.Scribe.ii'
        }
      ]
  
      admin_role = Role.find_by(name: 'Admin') # Ensure the role exists
  
      users_data.each do |user_data|
        user = User.find_or_create_by!(email: user_data[:email]) do |u|
          u.f_name = user_data[:f_name]
          u.l_name = user_data[:l_name]
          u.status = 'active'
          u.otp_enabled = false
          u.password = user_data[:password]
          u.password_confirmation = user_data[:password]
          u.confirmed_at = Time.current
        end
  
        if admin_role && !user.roles.include?(admin_role)
          user.roles << admin_role
          puts "Assigned 'Admin' role to #{user.email}"
        else
          puts "User #{user.email} already has 'Admin' role or role not found."
        end
      end
  
      puts "User creation process completed."
    end
  end
  