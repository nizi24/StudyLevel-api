class V2::LikesController < ApplicationController
  before_action :authorize, only: [:delete]

  def index
    user = User.find(params[:user_id])
    render json: user.likes.to_json(only: [:likeable_type, :likeable_id, :user_id])
  end

  def delete
    like = Like.find_by(like_params)
    if current_user == like.user && like.destroy!
      render json: like.to_json(only: [:likeable_type, :likeable_id, :user_id])
    end
  end

  private def like_params
    params.require(:like).permit(:likeable_id, :likeable_type, :user_id)
  end
end
