class CompaniesController < ApplicationController
    before_action :set_company, only: [:show, :update]
    # GET /company
    def show
      render json: @company, status: :ok
    end

    # PUT /company
    def update
      if @company.update(company_params)
        render json: { message: 'Company name updated successfully', name: @company.name }, status: :ok
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
  