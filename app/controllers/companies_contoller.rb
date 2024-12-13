class CompaniesController < ApplicationController
        before_action :set_company, only: [:show, :update]
  
        # GET /api/v1/company
        def show
          render json: { company_name: @company.name }, status: :ok
        end
  
        # PUT /api/v1/company
        def update
          if @company.update(company_params)
            render json: { message: 'Company name updated successfully', company_name: @company.name }, status: :ok
          else
            render json: { errors: @company.errors.full_messages }, status: :unprocessable_entity
          end
        end
  
        private
  
        # Fetch the singleton Company record
        def set_company
          @company = Company.first_or_create!(name: "Instant Impact") # Ensure a default exists
        end
  
        # Permit only the name parameter
        def company_params
          params.require(:company).permit(:name)
        end
    end
  